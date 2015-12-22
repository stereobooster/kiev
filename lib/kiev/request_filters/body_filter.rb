require "kiev/request_filters/base"
require "kiev/request_body_encoder"

module Kiev
  module RequestFilters
    class BodyFilter < Base
      JSON_CONTENT_TYPE = "application/json"
      FORM_URLENCODED_CONTENT_TYPE = "application/x-www-form-urlencoded"
      FORM_DATA_CONTENT_TYPE = "multipart/form-data"

      def call
        return encoded_request_body unless params_to_filter?
        filter_body_params
      end

      private

      def filter_body_params
        case request.media_type
        when FORM_URLENCODED_CONTENT_TYPE, FORM_DATA_CONTENT_TYPE
          params_hash = Rack::Utils.parse_nested_query(encoded_request_body)
          CGI.unescape(filter_params(params_hash).to_param)
        when JSON_CONTENT_TYPE
          params_hash = JSON.parse(encoded_request_body)
          filter_params(params_hash).to_json
        else
          encoded_request_body
        end
      end

      def encoded_request_body
        Kiev::RequestBodyEncoder.call(request)
      end
    end
  end
end
