require "kiev/request_filters/body/form_data"
require "kiev/request_filters/body/json"
require "kiev/request_filters/body/xml"
require "kiev/request_filters/body/default"

module Kiev
  module RequestFilters
    module Body
      JSON_CONTENT_TYPE = "application/json"
      FORM_DATA_CONTENT_TYPES = %w(application/x-www-form-urlencoded multipart/form-data)
      XML_CONTENT_TYPES = %w(text/xml application/xml)

      def self.for_content_type(content_type)
        case content_type
        when JSON_CONTENT_TYPE
          Json
        when *FORM_DATA_CONTENT_TYPES
          FormData
        when *XML_CONTENT_TYPES
          Xml
        else
          Default
        end
      end
    end
  end
end
