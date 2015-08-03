# kiev
A logging extension for Sinatra

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
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kiev. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.
