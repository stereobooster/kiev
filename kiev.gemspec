# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kiev/version"

Gem::Specification.new do |spec|
  spec.name          = "kiev"
  spec.version       = Kiev::VERSION
  spec.authors       = ["Igor Khodyrev", "Alexey Zhaboyedov"]
  spec.email         = ["Igor.Khodyrev@dataart.com", "Alexey.Zhaboyedov@dataart.com"]

  spec.summary       = %(Log your requests with a modern logger)
  spec.description   = %(Kiev provides logging capabilities to your request handlers)
  spec.homepage      = "https://github.com/blacklane/kiev"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    fail "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "reek", "~> 3.7.1"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "parser", "~> 2.2.3.0"
  spec.add_development_dependency "rubocop", "~> 0.35.1"

  spec.add_dependency "sinatra-contrib"
  spec.add_dependency "activesupport", "~> 4"
  spec.add_dependency "logstash-logger"
  spec.add_dependency "pheme", "~> 0.1.1"
  spec.add_dependency "classy_hash", "~> 0.1.5"
  spec.add_dependency "oga", "~> 2.2"
end
