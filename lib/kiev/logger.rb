require "sinatra/extension"
require "kiev/ext/rack/common_logger"
require "kiev/formatters/default"
require "kiev/middleware/request_logger"
require "kiev/middleware/request_id"

module Kiev
  module Logger
    extend Sinatra::Extension

    configure do
      if settings.logging
        logger_settings = Settings.new(settings)

        disable :raise_errors
        disable :show_exceptions
        disable :dump_errors

        set :log_level, logger_settings.log_level
        set :log_file, logger_settings.log_file

        set :logger, logger_settings.logger_instance

        use Middleware::RequestId
        use Middleware::RequestLogger, logger: settings.logger

        after do
          if env["sinatra.error"] && server_error?
            settings.logger.error(env["sinatra.error"])
          end
        end
      end
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

    def default_log_file
      -> { File.join(root, "log", "#{environment}.log") }
    end

    def logger_instance
      Logger.new(log_storage, "daily").tap do |logger|
        logger.level = Logger.const_get((log_level).to_s.upcase)
        logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        logger.formatter = Formatters::Default.new
      end
    end

    def log_storage
      log_file = app_settings.log_file

      return log_file if log_file == STDOUT

      FileUtils.mkdir_p(File.dirname(log_file))
      File.new(log_file, "a+").tap do |log_storage|
        log_storage.sync = true
        route_std_to_log_storage(log_storage) if app_settings.environment.to_s != "test"
      end
    end

    def route_std_to_log_storage(log_storage)
      STDOUT.reopen(log_storage)
      STDOUT.sync = true
      STDERR.reopen(log_storage)
      STDERR.sync = true
    end
  end
end
