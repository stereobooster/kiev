require "rack/request"
require "rack/response"

module Kiev
  module Middleware
    class Base
      attr_reader :app, :env, :options

      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def default_options
        {}
      end

      def before; end

      def call(env)
        @request, @response = nil
        @env = env
        before
        @app_response = @app.call(@env)
        after || @app_response
      end

      def after; end

      def request
        @request ||= Rack::Request.new(env)
      end

      def response
        @response ||= Rack::Response.new(@app_response[2], @app_response[0], @app_response[1])
      end
    end
  end
end
