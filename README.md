# StringReplacer

This is a very simple gem that uses regex to replace a string with handlebars notation. A simple use case can be to safely allow a user to define a string that can with a predefined set of avaiable methods that can also take some arguments.

There are other more robust solutions like https://github.com/Shopify/liquid, but if your are looking for a lightweight solution, this might be the way to go.


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

The idea is to simple extend the base StringReplacer::Replacer class and define the whitelist of methods you want to have available.

An example:
```ruby

class CustomStringReplacer < StringReplacer::Replacer
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
