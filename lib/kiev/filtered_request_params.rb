require "kiev/request_body_encoder"
require "kiev/request_filters/hash_filter"
require "kiev/request_filters/body"

module Kiev
  class FilteredRequestParams
    FILTERED_OUT_PARAM_VALUE = "FILTERED"

    def initialize(request)
      @request = request
      @params_to_filter = Set.new(Kiev.config[:filter_params])
    end

    def body
      @body ||= begin
        encoded_request_body = Kiev::RequestBodyEncoder.call(request)
        if params_to_filter?
          RequestFilters::Body.for_content_type(request.media_type).call(encoded_request_body, params_to_filter)
        else
          encoded_request_body
        end
      end
    end

    def query
      @query ||= begin
        if params_to_filter?
          RequestFilters::HashFilter.call(request.GET, params_to_filter).to_param
        else
          request.query_string
        end
      end
    end

    private

    def params_to_filter?
      params_to_filter.any?
    end

    attr_reader :request, :params_to_filter
  end
end
