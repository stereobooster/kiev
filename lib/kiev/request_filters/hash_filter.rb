module Kiev
  module RequestFilters
    class HashFilter
      def self.call(hash, params_to_filter)
        hash.each_with_object({}) do |(key, value), result|
          result[key] =
            case value
            when Hash
              call(value, params_to_filter)
            else
              params_to_filter.include?(key) ? Kiev::FilteredRequestParams::FILTERED_OUT_PARAM_VALUE : value
            end
        end
      end
    end
  end
end
