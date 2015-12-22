# kiev
A logging extension for Sinatra integrated with logstash

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kiev'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install kiev

## Usage

Register the Kiev::Logger in your app and you can make your requests loggable:

```ruby
require "kiev"

class MySweetSugarCandyApp < Sinatra::Base
  # Enable logging

  enable :logging

  # Set log file for a particular environment
  
  configure :development do
    set :log_file, STDOUT
  end

  # Disable logging for a particular environment
  
  configure :test do
    disable :logging
  end

  register Kiev::Logger

  # Add logstash logger
  add_logstash_logger sync: true, uri: "tcp://localhost:5228"
end
```

If you want to have additional methods in your logger, first you have to subclass `Kiev::MultisourceLogger`

```ruby
class MySweetLogger < Kiev::MultisourceLogger
  def track_money(booking_params)
    info(event: "money_income",
         amount: booking_params[:price],
         customer_id: booking_params[:user_id],
         message: "Payment from user #{booking_params[:user_id]} arrived. Amount: #{booking_params[:price]}.")
  end
end
```

And then set it as a logger.

```ruby
  set :logger, MySweetLogger.new
```

In order to have request-only parameters working, you have to set up a request store, e.g.

```ruby
# config/initializers/kiev.rb
Kiev.configure_request_store_middleware do |application|
  application.use Pliny::Middleware::RequestStore, store: Pliny::RequestStore
end

Kiev.configure_request_store do
  Pliny::RequestStore.store[:log_context] ||= {}
end
```

If you don't do this, any your request-only parameters will be discarded and not logged.

Kiev supports filtering of sensitive data. Currently it supports form-data and json requests.
Note that all other requests e.g. xml will not be filtered.

```ruby
Kiev.configure do |config|
  config["filter_params"] = ["credit_card_number", "credit_card_cvv"]
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kiev. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.
