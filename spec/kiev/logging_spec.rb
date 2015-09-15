require "spec_helper"
require "fileutils"
require "kiev"

describe Kiev::Logger do
  include Sinatra::TestHelpers

  describe "Logger" do
    describe "with Default Settings" do
      let(:log_file) { "#{tmp_path}/log/#{settings.environment}.log" }
      let(:log_file_content) { IO.read(log_file) }

      before do
        init_app
      end

      after do
        File.truncate("#{log_file}", 0)
      end

      def init_app
        path = tmp_path
        mock_app do
          set :root, "#{path}"
          set :logging, true

          register Kiev::Logger

          def message
            params[:msg]
              .try(:force_encoding, request.content_charset || Kiev::Middleware::RequestLogger::DEFAULT_CHARSET)
              .try(:encode, Kiev.config[:encoding])
          end

          get "/logger/test" do
            erb("Get Message: #{message}", layout: false)
          end

          post "/logger/test" do
            erb("Post Message: #{message}", layout: false)
          end

          get "/logger/error" do
            fail ArgumentError
          end
        end
      end

      describe ".registered" do
        before do
          File.delete(log_file)
          FileUtils.rm_rf("#{tmp_path}/log")

          init_app
        end

        it "should create a test.log file and proper directory structure" do
          expect(File).to exist(log_file)
        end
      end

      describe "Configuration" do
        it "should set :log_level to :info" do
          expect(settings.log_level).to eq(:info)
        end

        it "should set :log_file to [../log/< environment >.log]" do
          expect(settings.log_file).to eq("#{tmp_path}/log/test.log")
        end
      end

      describe "logging" do
        let(:ip_address) { "192.168.0.1" }

        it "should log GET request/response info" do
          get("/logger/test?msg=this-works")

          logged_content = log_file_content.strip.split("\n")

          expect(body).to eq "Get Message: this-works"
          expect(headers["X-Request-Id"]).to match(Kiev::Middleware::RequestId::UUID_PATTERN)
          expect(logged_content.first).to include(
            "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Started: GET /logger/test?msg=this-works"
          )
          expect(logged_content.last).to match(
            /\[INFO\] \[127\.0\.0\.1\] \[#{headers['X-Request-Id']}\] Responded with 200 \(\d+\.\d+ms\): #{body}/
          )
        end

        it "should log POST request/response info" do
          post("/logger/test?hello=world", msg: "this-works")

          logged_content = log_file_content.strip.split("\n")

          expect(body).to eq "Post Message: this-works"
          expect(headers["X-Request-Id"]).to match(Kiev::Middleware::RequestId::UUID_PATTERN)
          expect(logged_content.first).to include(
            "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Started: POST /logger/test?hello=world"
          )
          expect(logged_content[1]).to include(
            "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Request body: msg=this-works"
          )
          expect(logged_content.last).to match(
            /\[INFO\] \[127\.0\.0\.1\] \[#{headers["X-Request-Id"]}\] Responded with 200 \(\d+\.\d+ms\): #{body}/
          )
        end

        context "when body charset is not provided" do
          it "should treat POST body encoded with ISO-8859-1 and correctly log it" do
            post(
              "/logger/test",
              "msg=\xC3".force_encoding("ISO-8859-1"),
              "CONTENT_TYPE" => "application/x-www-form-urlencoded"
            )

            logged_content = log_file_content.strip.split("\n")

            expect(body).to eq "Post Message: Ã"
            expect(headers["X-Request-Id"]).to match(Kiev::Middleware::RequestId::UUID_PATTERN)
            expect(logged_content.first).to include(
              "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Started: POST /logger/test"
            )
            expect(logged_content[1]).to include(
              "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Request body: msg=Ã"
            )
            expect(logged_content.last).to match(
              /\[INFO\] \[127\.0\.0\.1\] \[#{headers["X-Request-Id"]}\] Responded with 200 \(\d+\.\d+ms\): #{body}/
            )
          end
        end

        context "when body charset is provided" do
          it "should encode POST body with provided charset and correctly log it" do
            post(
              "/logger/test",
              "msg=\xC3".force_encoding("ISO-8859-1").encode("UTF-8"),
              "CONTENT_TYPE" => "application/x-www-form-urlencoded;charset=UTF-8"
            )

            logged_content = log_file_content.strip.split("\n")

            expect(body).to eq "Post Message: Ã"
            expect(headers["X-Request-Id"]).to match(Kiev::Middleware::RequestId::UUID_PATTERN)
            expect(logged_content.first).to include(
              "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Started: POST /logger/test"
            )
            expect(logged_content[1]).to include(
              "[INFO] [127.0.0.1] [#{headers['X-Request-Id']}] Request body: msg=Ã"
            )
            expect(logged_content.last).to match(
              /\[INFO\] \[127\.0\.0\.1\] \[#{headers["X-Request-Id"]}\] Responded with 200 \(\d+\.\d+ms\): #{body}/
            )
          end
        end

        it "logs unhandled exceptions" do
          get("/logger/error")

          expect(log_file_content).to include("[ERROR] ArgumentError")
          expect(log_file_content).to match(/Responded with 500 \(\d+\.\d+ms\): <h1>Internal Server Error<\/h1>/)
        end

        it "logs ip address from HTTP_X_FORWARDED_FOR header" do
          get("/logger/test", {}, "HTTP_X_FORWARDED_FOR" => ip_address)

          logged_content = log_file_content.strip.split("\n")

          expect(logged_content.first).to include("[INFO] [#{ip_address}]")
        end

        it "logs ip address from HTTP_X_REAL_IP header" do
          get("/logger/test", {}, "HTTP_X_REAL_IP" => ip_address)

          logged_content = log_file_content.strip.split("\n")

          expect(logged_content.first).to include("[INFO] [#{ip_address}]")
        end

        it "logs ip address from REMOTE_ADDR header" do
          get("/logger/test", {}, "REMOTE_ADDR" => ip_address)

          logged_content = log_file_content.strip.split("\n")

          expect(logged_content.first).to include("[INFO] [#{ip_address}]")
        end

        it "should return an instance of MultsourceLogger" do
          expect(settings).to respond_to(:logger)
          expect(settings.logger).to be_a_kind_of(Kiev::MultisourceLogger)
        end

        it "should NOT log lower logging levels" do
          settings.logger.debug("debug message")

          expect(log_file_content).to be_empty
        end

        it "should log higher logging levels" do
          settings.logger.error("error message")

          expect(log_file_content).to match(/\[ERROR\] error message/)
        end
      end
    end

    describe "with Custom Settings" do
      let(:log_file) { "#{tmp_path}/log/custom.log" }
      let(:log_file_content) { IO.read(log_file) }

      def init_app
        path = tmp_path
        mock_app do
          set :root, "#{path}"
          set :logging, true

          set :log_level, :debug
          set :log_file, "#{path}/log/custom.log"

          register Kiev::Logger
        end
      end

      before do
        init_app
      end

      after do
        File.truncate("#{log_file}", 0)
      end

      describe ".registered" do
        before do
          File.delete(log_file)
          FileUtils.rm_rf("#{tmp_path}/log")
          init_app
        end

        it "should create a custom.log file and proper directory structure" do
          expect(File).to exist(log_file)
        end
      end

      describe "Configuration" do
        it "should set :log_level to :debug" do
          expect(settings.log_level).to eq(:debug)
        end

        it "should set :log_file to [../log/custom.log]" do
          expect(settings.log_file).to eq("#{tmp_path}/log/custom.log")
        end
      end

      it "logs into a custom file" do
        settings.logger.error("error message")

        expect(log_file_content).to match(/\[ERROR\] error message/)
      end
    end
  end
end
