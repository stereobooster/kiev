module Kiev
  module RequestFilters
    module Body
      class Json
        def self.call(request_body, params_to_filter)
          params_hash = JSON.parse(request_body)
          HashFilter.call(params_hash, params_to_filter).to_json
        end
      end
    end
  end
end
