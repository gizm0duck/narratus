require 'logger'

module Narratus
  class Logger < ::Logger

    attr_reader :logger
    def initialize(slogger)
      @logger = slogger
    end

    def add(severity, message = nil, progname = nil, &block)
      return unless nid = Narratus::Transaction.id

      msg_out = {
        service: "NARRATUS-#{Narratus::VERSION}",
        severity: severity,
        progname: progname,
        hostname: Socket.gethostname,
        timestamp: DateTime.now.to_f,
        formattedTime: DateTime.now.strftime,
        transaction: nid,
        pid: $$,
        thread: Thread.current.object_id,
      }

      # TODO: document how an exception might happen here (JN)
      begin
        msg_out[:block] = yield if block_given?
        msg_in = ActiveSupport::JSON.decode(message).symbolize_keys
        msg_out.merge! msg_in
        log_out = ActiveSupport::JSON.encode(Hash[*msg_out.sort.flatten])
      rescue Exception => e
        begin
          msg_out.merge! ActiveSupport::JSON.decode(message)
          log_out = ActiveSupport::JSON.encode(msg_out)
        rescue Exception => e2
          Rails.logger.info "Exception thrown from Narratus::Logger#add:"
          Rails.logger.info "Original exception: #{e.class} #{e.message} #{e.backtrace}"
          Rails.logger.info "Inner exception: #{e.class} #{e2.message} #{e2.backtrace}"
        end
      end
      PubSub.publish(log_out) if Narratus.config.publish
      logger.add(severity, "#{log_out}", progname, &block)
    end

    def info(message = nil, progname = nil, &block)
      add(::Logger::INFO, message, progname, &block)
    end

    def debug(message = nil, progname = nil, &block)
      add(::Logger::DEBUG, message, progname, &block)
    end

    def warn(message = nil, progname = nil, &block)
      add(::Logger::WARN, message, progname, &block)
    end
  end
end
