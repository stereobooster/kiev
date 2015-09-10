module Kiev
  class Config
    include Singleton
    delegate :[], :[]=, to: :@config

    def initialize
      @config = HashWithIndifferentAccess.new(
        application: "MyApp",
        log_type: "kiev-gem",
        environment: ENV["RACK_ENV"] || "development"
      )
    end
  end
end