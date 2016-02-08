require "kiev/middleware/base"
# please add changes here to core's Instruments as well

module Kiev
  module Middleware
    class RequestId < Base
      # note that this pattern supports either a full UUID, or a "squashed" UUID:
      #
      #     full:     01234567-89ab-cdef-0123-456789abcdef
      #     squashed: 0123456789abcdef0123456789abcdef
      #
      UUID_PATTERN =
        /\A[a-f0-9]{8}-?[a-f0-9]{4}-?[a-f0-9]{4}-?[a-f0-9]{4}-?[a-f0-9]{12}\Z/

      attr_accessor :request_ids

      def before
        self.request_ids = [SecureRandom.uuid] + extract_request_ids

        # make ID of the request accessible to consumers down the stack
        env["REQUEST_ID"] = request_ids[0]

        # Extract request IDs from incoming headers as well. Can be used for
        # identifying a request across a number of components in SOA.
        env["REQUEST_IDS"] = request_ids
      end

      def after
        response["X-REQUEST-ID"] = request_ids[0]
        response.to_a
      end

      private

      def extract_request_ids
        raw_request_ids.map(&:strip).select { |id| id.match(UUID_PATTERN) }
      end

      def raw_request_ids
        %w(HTTP_REQUEST_ID HTTP_X_REQUEST_ID).each_with_object([]) do |request_ids, key|
          if (ids = env[key])
            request_ids += ids.split(",")
          end
          request_ids
        end
      end
    end
  end
end
