require 'rails/railtie'

module Narratus
  class Railtie < Rails::Railtie
    config.narratus = ActiveSupport::OrderedOptions.new
    config.narratus.enabled = false
    config.narratus.key = "NO_APP_SPECIFIED"
    config.narratus.logger = Rails.logger if defined?(Rails) && Rails.logger
    config.narratus.ignored_notification_names = []
    config.narratus.ignored_database_actions = []
    config.narratus.publish = nil
    config.narratus.publish_key = ''

    initializer :narratus do |app|
      if app.config.narratus.enabled
        require "narratus/railties/controller_extensions"

        Narratus.configure do |config|
          config.key = app.config.narratus[:key] || self.app_name
          config.logger = app.config.narratus[:logger]
          config.ignored_notification_names = app.config.narratus[:ignored_notification_names]
          config.ignored_database_actions = app.config.narratus[:ignored_database_actions]
          config.publish = app.config.narratus[:publish]
          config.publish_key = app.config.narratus[:publish_key]
        end
        app.config.middleware.insert_before "Rails::Rack::Logger", "Narratus::Middleware"
        Narratus.subscribe_all
      end
    end

    private

    def self.app_name
      Rails.application.class.to_s.split("::").first
    end
  end
end
