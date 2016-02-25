require "benchmark"
require "logger"
require "kiev/middleware/base"
require "kiev/struct_from_hash"
require "kiev/request_filters/query_params_filter"
require "kiev/request_filters/body_filter"

module Kiev
  module Middleware
    class RequestLogger < Base
      def before
        prepare_data

        log_request unless disable_request_logging?

        env["request_duration"] = 0
      end

      def prepare_data
        request_store = Kiev.request_store
        request_store[:ip] = ip
        request_store[:request_id] = request_id
        request_store[:verb] = request.request_method
        request_store[:path] = request.path
        request_store[:query] = query_string if query_string.present?
        request_store[:uniform_request_id] = uniform_request_id if uniform_request_id
        request_store[:initial_app] = initial_app if initial_app
        request_store[:caller_app] = caller_app if caller_app
      end

      def call(env)
        original_response = nil

        env["request_duration"] = Benchmark.realtime { original_response = super(env) }

        log_response unless disable_request_logging?

        original_response
      end

      protected

      def ip
        env["HTTP_X_FORWARDED_FOR"] || env["HTTP_X_REAL_IP"] || env["REMOTE_ADDR"] || "-"
      end

      def request_id
        env["REQUEST_ID"]
      end

      def uniform_request_id
        Pheme.uniform_request_id
      end

      def initial_app
        Pheme.initial_app
      end

      def caller_app
        env[Pheme::APP_PARAM]
      end

      def log_request
        logger.info RequestInfoFormatter.create(request_parameters).to_h

        return if request.get? || request.head? || request.delete?

        logger.info RequestBodyFormatter.create(request_body_parameters).to_h
      end

      def log_response
        logger.info ResponseInfoFormatter.create(response_parameters).to_h
      end

      def request_body
        RequestFilters::BodyFilter.call(request)
      end

      def query_string
        @query_string ||= RequestFilters::QueryParamsFilter.call(request)
      end

      def base_logging_info
        BaseRequestDataFormatter.create(
          ip: ip,
          request_id: request_id
        )
      end

      def request_parameters
        {
          query: query_string,
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
          body: filtered_body,
          base_request_data: base_logging_info
        }
      end

      def filtered_body
        disable_response_body_logging? ? "EXCLUDED" : response.body.join
      end

      private

      def logger
        @logger ||= @options[:logger] || Logger.new(STDOUT)
      end

      def disable_request_logging?
        @disable_request_logging ||= Kiev.config.disable_request_logging?(request)
      end

      def disable_response_body_logging?
        Kiev.config.disable_response_body_logging?(response)
      end

      BaseRequestDataFormatter = Struct.new(:ip, :request_id) do
        extend StructFromHash

        def to_s
          "[#{ip}] [#{request_id}]"
        end
      end

      RequestInfoFormatter = Struct.new(:base_request_data, :query, :path, :request_method) do
        extend StructFromHash

        def to_h
          hash = {
            event: "request_started",
            ip: base_request_data.ip,
            request_id: base_request_data.request_id,
            verb: request_method,
            path: path,
            message: to_s
          }

          hash.merge(query: query) if query.present?
          hash
        end

        def to_s
          query_info = query.present? ? "?#{query}" : ""

          "#{base_request_data} Started: #{request_method} #{path}#{query_info}"
        end
      end

      RequestBodyFormatter = Struct.new(:base_request_data, :body) do
        extend StructFromHash

        def to_h
          {
            event: "request_body",
            ip: base_request_data.ip,
            request_id: base_request_data.request_id,
            data: body,
            message: to_s
          }
        end

        def to_s
          "#{base_request_data} Request body: #{body}"
        end
      end

      ResponseInfoFormatter = Struct.new(:base_request_data, :duration, :status, :body) do
        extend StructFromHash

        def to_h
          {
            event: "request_finished",
            ip: base_request_data.ip,
            request_id: base_request_data.request_id,
            request_duration: duration,
            data: body,
            status: status,
            message: to_s
          }
        end

        def to_s
          "#{base_request_data} Responded with #{status} (#{duration}ms): #{body}"
        end
      end
    end
  end
end
