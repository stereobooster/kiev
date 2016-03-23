module Kiev
  module RequestFilters
    module Body
      class FormData
        def self.call(request_body, params_to_filter)
          params_hash = Rack::Utils.parse_nested_query(request_body)
          CGI.unescape(HashFilter.call(params_hash, params_to_filter).to_param)
        end
      end
    end
  end
end
