require "spec_helper"
require "kiev"

describe Kiev::Logger do
  [
    [:filter_params, -> {}, "a/an Array"],
    [:application, -> {}, "a/an String"],
    [:application, -> {}, "a/an String"],
    [:log_type, -> {}, "a/an String"],
    [:environment, -> {}, "a/an String"],
    [:encoding, -> {}, "a/an String"],
    [:disable_request_logging, :wrong_value, "one of true or false, Proc"],
    [:disable_response_body_logging, :wrong_value, "one of true or false, Proc"]
  ].each do |param, incorrect_value, error_message|
    context "when trying to configure #{param} with incorrect value" do
      let!(:initial_value) { Kiev.config[param] }

      let(:configure) do
        Kiev.configure do |config|
          config[param] = incorrect_value
        end
      end

      after do
        Kiev.configure do |config|
          config[param] = initial_value
        end
      end

      it "fails with 'RuntimeError'" do
        expect { configure }.to raise_error(RuntimeError, ":#{param} is not #{error_message}")
      end
    end
  end
end
