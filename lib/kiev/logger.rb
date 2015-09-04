require "sinatra/extension"
require "kiev/ext/rack/common_logger"
require "kiev/formatters/default"
require "kiev/middleware/request_logger"
require "kiev/middleware/request_id"
require "kiev/multisource_logger"

module Kiev
  module Logger
    extend Sinatra::Extension

    def add_logstash_logger(options)
      return unless settings.logging
      logger = LogStashLogger.new(Array.wrap(options))
      logger.level = ::Logger.const_get(sym_to_const_name(settings.log_level))
      settings.logger << logger
    end

    protected

    def route_stderr_to_log_storage(log_storage)
      return if settings.environment.to_s == "test"
      log_storage = STDOUT if log_storage == :stdout
      STDERR.reopen(log_storage)
      STDERR.sync = true
    end

    def sym_to_const_name(sym)
      sym.to_s.upcase
    end

    def configure_logging
      logger_settings = Settings.new(settings)

      disable :raise_errors
      disable :show_exceptions
      disable :dump_errors

      set :log_level, logger_settings.log_level
      set :log_file, logger_settings.log_file

      set :logger, logger_settings.logger

      add_logstash_logger logger_settings.default_file_logger_options
      route_stderr_to_log_storage(logger_settings.log_file)

      use Middleware::RequestLogger, logger: settings.logger

      after do
        exception = request_error
        logger.track_exception(exception) if exception && server_error?
      end
    end

    configure do
      helpers do
        def request_error
          env["sinatra.error"]
        end

        def logger
          settings.logger
        end
      end

      use Middleware::RequestId
      Kiev.use_request_store_middleware(self)

      configure_logging if settings.logging
    end
  end

  class Settings
    attr_reader :app_settings

    def initialize(app_settings)
      @app_settings = app_settings
    end

    def log_level
      app_settings.respond_to?(:log_level) ? app_settings.log_level : :info
    end

    def log_file
      app_settings.respond_to?(:log_file) ? app_settings.log_file : default_log_file
    end

    def logger
      app_settings.respond_to?(:logger) ? app_settings.logger : logger_instance
    end

    def logger_instance
      MultisourceLogger.new
    end

    def logger_log_file
      file = log_file

      if file == :stdout
        "stdout:/"
      elsif file.match(/^file:/)
        file
      else
        "file://#{file}"
      end
    end

    def default_log_file
      File.join(app_settings.root, "log", "#{app_settings.environment}.log")
    end

    def default_file_logger_options
      { sync: true, uri: logger_log_file, formatter: Formatters::Default }
    end
  end
end
