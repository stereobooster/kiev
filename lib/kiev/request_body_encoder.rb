module Kiev
  class RequestBodyEncoder
    DEFAULT_CHARSET = "ISO-8859-1"

    def self.call(request)
      request_body = request.body.read
      request.body.rewind
      charset = request.content_charset || DEFAULT_CHARSET
      request_body.force_encoding(charset).encode(Kiev.config[:encoding])
    end
  end
end
