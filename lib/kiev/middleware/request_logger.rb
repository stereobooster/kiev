require "benchmark"
require "forwardable"
require "logger"
require "kiev/middleware/base"
require "kiev/struct_from_hash"

module Kiev
  module Middleware
    class RequestLogger < Base
      extend Forwardable

      def_delegator :request, :body, :raw_request_body

      def before
        log_request

        env["request_duration"] = 0
      end

      def call(env)
        original_response = nil

        env["request_duration"] = Benchmark.realtime { original_response = super(env) }

        logger.info ResponseInfoFormatter.create(response_parameters).to_s

        original_response
      end

      protected

      def log_request
        logger.info RequestInfoFormatter.create(request_parameters).to_s

        return if request.get? || request.head?

        logger.info RequestBodyFormatter.create(request_body_parameters).to_s
      end

      def request_body
        raw_request_body.read.tap do
          raw_request_body.rewind
        end
      end

      def base_logging_info
        BaseRequestDataFormatter.create(
          ip: env["HTTP_X_FORWARDED_FOR"] || env["HTTP_X_REAL_IP"] || env["REMOTE_ADDR"] || "-",
          request_id: env["REQUEST_ID"]
        )
      end

      def request_parameters
        {
          query: request.query_string,
          path: request.path,
          request_method: request.request_method,
          base_request_data: base_logging_info
        }
      end

      def request_body_parameters
        {
          body: request_body,
          base_request_data: base_logging_info
        }
      end

      def response_parameters
        {
          duration: (env["request_duration"] * 1000).round(2),
          status: response.status,
          body: response.body.join,
          base_request_data: base_logging_info
        }
      end

      private

      def logger
        @logger ||= @options[:logger] || Logger.new(STDOUT)
      end

      BaseRequestDataFormatter = Struct.new(:ip, :request_id) do
        extend StructFromHash

        def to_s
          "[#{ip}] [#{request_id}]"
        end
      end

      RequestInfoFormatter = Struct.new(:base_request_data, :query, :path, :request_method) do
        extend StructFromHash

        def to_s
          query_info = query.present? ? "?#{query}" : ""

          "#{base_request_data} Started: #{request_method} #{path}#{query_info}"
        end
      end

      RequestBodyFormatter = Struct.new(:base_request_data, :body) do
        extend StructFromHash

        def to_s
          "#{base_request_data} Request body: #{body}"
        end
      end

      ResponseInfoFormatter = Struct.new(:base_request_data, :duration, :status, :body) do
        extend StructFromHash

        def to_s
          "#{base_request_data} Responded with #{status} (#{duration}ms): #{body}"
        end
      end
    end
  end
end
