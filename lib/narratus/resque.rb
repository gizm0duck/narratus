require 'resque'
require 'rails'

module Narratus::Resque
  def self.initialize!
    ::Resque::Job.send(:include, Narratus::Resque::Job)
    ::Resque::Worker.send(:include, Narratus::Resque::Worker)

    ::Resque.after_fork do |job|
      Narratus::Transaction.create(Narratus::Resque.key)
    end
  end

  def self.key
    @key ||= Narratus.config.key ? "#{Narratus.config.key}-RESQUE" : "RESQUE"
  end

  module Job
    def perform_with_narratus_instrumentation
      ActiveSupport::Notifications.instrument("perform_job.resque") do |asn_payload|
        asn_payload.merge!(resque: payload)
      end
      perform_without_narratus_instrumentation
    end

    def inspect_with_caller_nid
      inspect_without_caller_nid.gsub /\)$/, " | #{payload['caller_nid'].inspect})"
    end

    def self.included base
      base.send :alias_method_chain, :perform, :narratus_instrumentation
      base.send :alias_method_chain, :inspect, :caller_nid

      base.instance_eval do
        # TODO: review the following extensions.  These definitions of .create and destroy clobber the
        # original definitions in Resque::Job in order to (A) add the current narratus transaction id to
        # the job's payload when we call .create or (B) to ignore that part of the payload when querying
        # for jobs to be removed by .destroy.  This approach is invasive and brittle, but seems to be
        # the only feasible approach at the moment.  If we can find another way, we should.  (JN)

        unless ::Resque::Version == '1.24.1'
          raise 'Resque version has changed; review Narratus::Resque::Job extensions'
        end

        def create(queue, klass, *args)
          ::Resque.validate(klass, queue)

          nid = Narratus::Transaction.id
          if ::Resque.inline?
            new(:inline, 'class' => klass.to_s, 'args' => decode(encode(args)), 'caller_nid' => nid).perform
          else
            ::Resque.push(queue, class: klass.to_s, args: args, caller_nid: nid)
          end
        end

        # Original implementation from resque-1.24.1:
        # ---
        # def self.create(queue, klass, *args)
        #   Resque.validate(klass, queue)
        #
        #   if Resque.inline?
        #     # Instantiating a Resque::Job and calling perform on it so callbacks run
        #     # decode(encode(args)) to ensure that args are normalized in the same manner as a non-inline job
        #     new(:inline, {'class' => klass, 'args' => decode(encode(args))}).perform
        #   else
        #     Resque.push(queue, :class => klass.to_s, :args => args)
        #   end
        # end

        def destroy(queue, klass, *args)
          klass = klass.to_s
          queue = "queue:#{queue}"
          destroyed = 0

          redis.lrange(queue, 0, -1).each do |string|
            payload = decode(string)
            if payload['class'] == klass && (args.empty? || payload.except('caller_nid') == args)
              destroyed += redis.lrem(queue, 0, string).to_i
            end
          end

          destroyed
        end

        # Original implementation from resque-1.24.1:
        # ---
        # def self.destroy(queue, klass, *args)
        #   klass = klass.to_s
        #   queue = "queue:#{queue}"
        #   destroyed = 0
        #
        #   if args.empty?
        #     redis.lrange(queue, 0, -1).each do |string|
        #       if decode(string)['class'] == klass
        #         destroyed += redis.lrem(queue, 0, string).to_i
        #       end
        #     end
        #   else
        #     destroyed += redis.lrem(queue, 0, encode(:class => klass, :args => args))
        #   end
        #
        #   destroyed
        # end
      end
    end
  end

  module Worker
    def self.included(base)
      base.send :alias_method_chain, :log, :transaction_id
    end

    def log_with_transaction_id(message)
      # TODO: this seems to be broken; the NID is blank here (JN)
      log_without_transaction_id "#{Narratus::Transaction.id} #{message}"
    end
  end
end
