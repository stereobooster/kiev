module Kiev
  module RequestFilters
    class Base
      FILTERED_OUT_PARAM_VALUE = "FILTERED"

      def self.call(request)
        new(request).call
      end

      def initialize(request)
        @request = request
        @params_to_filter = Set.new(Kiev.config[:filter_params])
      end

      def call
        fail NotImplementedError
      end

      private

      def params_to_filter?
        params_to_filter.any?
      end

      def filter_params(params_hash)
        params_hash.each_with_object({}) do |(key, value), result|
          result[key] =
            case value
            when Hash
              filter_params(value)
            else
              params_to_filter.include?(key) ? FILTERED_OUT_PARAM_VALUE : value
            end
        end
      end

      attr_reader :request, :params_to_filter
    end
  end
end
