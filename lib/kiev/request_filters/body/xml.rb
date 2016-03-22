require "oga"

module Kiev
  module RequestFilters
    module Body
      class Xml
        def self.call(request_body, params_to_filter)
          document = Oga.parse_xml(request_body)
          params_to_filter.each do |param|
            sensitive_param = document.at_xpath("//#{param}/text()")
            sensitive_param.try!(:text=, Kiev::FilteredRequestParams::FILTERED_OUT_PARAM_VALUE)
          end
          document.to_xml
        end
      end
    end
  end
end
