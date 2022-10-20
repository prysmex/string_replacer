# StringReplacer

This is a very simple gem that uses regex to replace a string with handlebars notation. A simple use case can be to safely allow a user to define a string that can with a predefined set of avaiable methods that can also take some arguments.

There are other more robust solutions like https://github.com/Shopify/liquid, but if your are looking for a very lightweight extendible solution, this might be the way to go.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'string_replacer'
```

And then execute:

```ruby
bundle
```

Or install it yourself as:

```ruby
gem install string_replacer
```

## Usage

The idea is to simple extend the base StringReplacer::Replacer class and user the `register_helper` class method to define a whitelist of methods you want to have available.

An example:

```ruby
class CustomStringReplacer < StringReplacer::Replacer
  register_helper(:i18n) do |argument|
    I18n.t(argument.strip)
  end
  
  register_helper(:upcase) do |argument|
    argument.upcase
  end
end

replacer = CustomStringReplacer.new('The {{upcase(translation)}} of hello is: {{i18n(hello)}}')

replacer.replace
# returns 'The TRANSLATION of hello is: hola'
```

You can even nest multiple methods like this.

```ruby
replacer = CustomStringReplacer.new('The translation of hello is: {{upcase(i18n(hello))}}')

replacer.replace
# returns 'The translation of hello is: HOLA'
```

## Errors

If there are any errors (like definining a method inside the handlebars that is not registered) execution of the
replacement is halted and the errors can be accessed via de `errors` method.

```ruby
replacer = CustomStringReplacer.new('This will cause an {{upcase(error)}} {{some_unregisered_method()}}')
replacer.replace
# returns 'This will cause an ERROR {{some_unregisered_method()}}'

replacer.errors
# returns [#<NoMethodError: Unregistered helper 'some_unregisered_method' while interpolating '{{some_unregisered_method()}}'>]
```

If you want errors to be raised, simply use `replace!`

## Hash arguments

It is possible to pass a hash of arguments that can be accessed by the registered methods. This is helpful when you need some context that is not provided
by the handlebars expression.

```ruby
class AnotherStringReplacer < StringReplacer::Replacer
  register_helper(:current_username) do
    @passed_data[:user_name]
  end
end

replacer = AnotherStringReplacer.new('The name of the current user name is: {{current_username()}}!', {user_name: 'Yoda'})
replacer.replace
# returns 'The name of the current user name is: Yoda!'
```