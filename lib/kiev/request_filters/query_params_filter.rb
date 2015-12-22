require "kiev/request_filters/base"

module Kiev
  module RequestFilters
    class QueryParamsFilter < Base
      def call
        return unfiltered_query_string unless params_to_filter?
        filter_params(request.GET).to_param
      end

      private

      def unfiltered_query_string
        request.query_string
      end
    end
  end
end
