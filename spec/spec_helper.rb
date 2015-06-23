$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "kiev"
require "rack/test"
require "sinatra/test_helpers"
require "helpers/path_helper"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include PathHelper
end
