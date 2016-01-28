require "classy_hash"

module Kiev
  class Config
    include Singleton

    SCHEMA = {
      application: String,
      log_type: String,
      environment: String,
      encoding: String,
      filter_params: Array,
      disable_request_logging: [FalseClass, TrueClass, Proc],
      disable_response_body_logging: [FalseClass, TrueClass, Proc]
    }

    def initialize
      set_defaults
      validate_parameters
    end

    def [](key)
      config[key]
    end

    def []=(key, value)
      config[key] = value
      validate_parameters
    end

    def disable_request_logging?(request)
      call_proc(:disable_request_logging, request)
    end

    def disable_response_body_logging?(response)
      call_proc(:disable_response_body_logging, response)
    end

    private

    def set_defaults
      @config = HashWithIndifferentAccess.new(
        application: "MyApp",
        log_type: "kiev-gem",
        environment: ENV["RACK_ENV"] || "development",
        encoding: "UTF-8",
        filter_params: [],
        disable_request_logging: -> (request) { request.path.match(%r{^\/ping}) },
        disable_response_body_logging: -> (_response) { false }
      )
    end

    def validate_parameters
      ClassyHash.validate(config, SCHEMA)
    end

    def call_proc(param, value)
      param = config[param]
      param.is_a?(Proc) ? param.call(value) : param
    end

    attr_accessor :config
  end
end
