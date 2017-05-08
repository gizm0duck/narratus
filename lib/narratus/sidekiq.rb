module Narratus
  module Sidekiq
    def self.initialize!
      ::Sidekiq.configure_client do |config|
        config.client_middleware {|chain| chain.add ClientMiddleware }
      end

      ::Sidekiq.configure_server do |config|
        config.server_middleware {|chain| chain.add ServerMiddleware }
        config.client_middleware {|chain| chain.add ClientMiddleware }
      end
    end

    def self.key
      @key ||= Narratus.config.key ? "#{Narratus.config.key}-SIDEKIQ" : "SIDEKIQ"
    end

    class ClientMiddleware
      def call(worker_class, job, queue, redis_pool)
        job['caller_nid'] = Narratus::Transaction.id

        ActiveSupport::Notifications.instrument("perform_async.sidekiq") do |asn_payload|
          asn_payload.merge!(sidekiq: job)
        end

        yield
      end
    end

    class ServerMiddleware
      def call(worker, job, queue)
        Narratus::Transaction.create(Narratus::Sidekiq.key)

        ActiveSupport::Notifications.instrument("perform.sidekiq") do |asn_payload|
          asn_payload.merge!(sidekiq: job)
        end

        yield
      end
    end

  end
end

