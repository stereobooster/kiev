require "active_support/all"
require "logstash-logger"
require "kiev/version"
require "kiev/config"
require "kiev/logger"

module Kiev
  def self.config
    Config.instance
  end

  def self.configure(&_block)
    yield config
  end

  def self.configure_request_store(&block)
    define_singleton_method(:request_store, &block)
  end

  def self.configure_logger(&block)
    LogStashLogger.configure(&block)
  end

  def self.customize_logger_event(&block)
    LogStashLogger.configure do |config|
      config.customize_event(&block)
    end
  end

  def self.configure_request_store_middleware(&block)
    define_singleton_method(:use_request_store_middleware, &block)
  end

  def self.request_store
    {}
  end

  def self.use_request_store_middleware(_application)
  end

  customize_logger_event do |event|
    event["application"] = config["application"]
    event["type"]        = config["log_type"]
    event["environment"] = config["environment"]
    event.append(Kiev.request_store)

    event_data = event["data"]

    if event_data && !event_data.is_a?(String)
      if event_data.respond_to? :to_json
        event["data"] = event_data.to_json
      else
        event["data"] = event_data.to_s
      end
    end
  end
end
