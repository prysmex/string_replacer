# StringReplacer

This is a very simple gem that uses regex to replace a string with handlebars notation. A simple use case can be to safely allow a user to define a string that can with a predefined set of avaiable methods that can also take some arguments.

The idea is to simple extend the base StringReplacer class and define the whitelist of methods you want to have available.

An example:
```ruby

class CustomStringReplacer < StringReplacer
  def i18n(argument)
    I18n.t(argument.strip)
  end
  
  def upcase(argument)
    argument.upcase
  end
end

your_string = CustomStringReplacer.new('The {{upcase(translation)}} of hello is: {{i18n(hello)}}')

your_string.replace
# returns 'The TRANSLATION of hello is: hola'
```

You can even nest multiple methods like this.

```ruby
your_string = CustomStringReplacer.new('The translation of hello is: {{upcase(i18n(hello))}}')

your_string.replace
# returns 'The translation of hello is: HOLA'
```



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'string_replacer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install string_replacer

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/string_replacer.
