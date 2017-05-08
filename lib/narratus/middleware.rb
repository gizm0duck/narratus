module Narratus
  class Middleware
    KEY_HEADER = 'X_NARRATUS_KEY'
    ID_HEADER = 'X_NARRATUS_ID'

    def initialize(app, options = {})
      @app = app
      @key = Narratus.config.key ? "#{Narratus.config.key}-WEB" : "WEB"
    end

    def call(env)
      key = env.fetch("HTTP_#{KEY_HEADER}", @key)
      Narratus::Transaction.create key
      env.store("HTTP_#{ID_HEADER}",Narratus::Transaction.id)
      @app.call(env)
    ensure
      Narratus::Transaction.destroy
    end
  end
end