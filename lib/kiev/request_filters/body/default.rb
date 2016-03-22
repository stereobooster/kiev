module Kiev
  module RequestFilters
    module Body
      class Default
        def self.call(request_body, _params_to_filter)
          request_body
        end
      end
    end
  end
end
