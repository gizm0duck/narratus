require 'narratus/version'
require 'narratus/config'
require 'narratus/transaction'
require 'narratus/middleware'
# require 'narratus/resque'
# require 'narratus/sidekiq'
require 'narratus/pub_sub'
require 'narratus/logger'
require 'narratus/railtie' if defined?(Rails)

module Narratus
  def self.config
    @@config ||= Config.new
  end

  def self.configure
    yield self.config
    # Narratus::Resque.initialize! if defined? Resque
    # Narratus::Sidekiq.initialize! if defined? Sidekiq
  end

  def self.subscribe_all
    ActiveSupport::Notifications.subscribe do |name, start, finish, id, payload|
      next if ignore_notification?(name, payload)

      message = { notification: { name: name, start: start, finish: finish, id: id } }
      severity = Logger::INFO

      # TODO: document how exception notifications are different and need special handling (JN)
      if payload[:exception].present?
        payload[:exception] = payload[:exception].flatten.join("\t")
        payload[:status] ||= 500
        severity = Logger::FATAL
      end
      # message[:payload] = payload
      pload = payload.dup
      if pload[:headers]
        pload[:headers] = pload[:headers].to_h
        pload[:headers].delete 'rack.errors'
        pload[:headers].delete 'rack.hijack'
        pload[:headers].delete 'puma.config'
        pload[:headers].delete 'action_dispatch.logger'
        pload[:headers].delete 'action_dispatch.key_generator'
      end
      if pload[:params]
        pload[:params] = pload[:params].to_h
      end
      
      message[:payload] = pload
      encoded_message = ActiveSupport::JSON.encode(message)
      Narratus.config.logger.add(severity, encoded_message, Narratus.config.key)
    end
  end

  def self.ignore_notification?(name, payload)
    if name == 'sql.active_record'
      first_statement = payload[:sql].to_s.split(" ")[0]
      return true if Narratus.config.ignored_database_actions.any? {|matcher| matcher.match(first_statement).present? }
    end
    Narratus.config.ignored_notification_names.any?{|matcher| matcher.match(name).present? }
  end
end
