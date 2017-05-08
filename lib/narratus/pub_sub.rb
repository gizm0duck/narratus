require 'redis'

module Narratus::PubSub
  def self.publish(log_out)
    # TEMPORARY HACK: comment out narratus pub-sub code to prevent massive app server outages
    # if the recommendation instance happens to go down again. (STW/JA/JN)
    redis = Narratus.config.publish
    begin
      redis.publish Narratus.config.publish_key, log_out
    rescue SocketError

    end
  end

  def self.configured?
    true
  end

  # class << self
  #   include ::NewRelic::Agent::MethodTracer
  # end
end
