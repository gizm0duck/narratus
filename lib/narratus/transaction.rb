begin
  require 'securerandom'
rescue
  require 'active_support/secure_random'
end

module Narratus
  module Transaction
    def self.create(key = nil)
      Thread.current[:narratus_transaction_id] = "#{key ? "#{key}-" : ""}#{SecureRandom.hex(10)}"
    end

    def self.destroy
      Thread.current[:narratus_transaction_id] = nil
    end

    def self.id=(id)
      Thread.current[:narratus_transaction_id] = id
    end

    def self.id
      Thread.current[:narratus_transaction_id]
    end
  end
end
