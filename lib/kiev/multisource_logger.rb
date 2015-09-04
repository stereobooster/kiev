module Kiev
  class MultisourceLogger
    attr_reader :loggers

    def initialize(loggers = [])
      @loggers = Array(loggers).clone
    end

    def <<(logger)
      @loggers << logger
      self
    end

    def track_exception(exception)
      error(event: "exception",
            exception_class: exception.class.to_s,
            message: exception.message,
            backtrace: exception.backtrace.join("\n"))
    end

    def method_missing(method_name, *args)
      return super if loggers.any? { |logger| !logger.respond_to?(method_name) }

      define_singleton_method(method_name) do |*arguments|
        loggers.map { |logger| logger.public_send(method_name, *arguments) }.all?
      end

      public_send(method_name, *args)
    end
  end
end
