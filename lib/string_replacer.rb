require "string_replacer/version"

module StringReplacer
  class Replacer
  
    HANDLEBARS_REGEX = /{{.*?}}/
    INNERMOST_METHOD_REGEX = /{{.*?\b((\w+)\(((?=[^(]*?\)).*?)\))[) ]*}}/
  
    attr_reader :string
  
    def initialize(string)
      @string = string
    end
  
    def replace
      string = @string
      string.scan(HANDLEBARS_REGEX).each do |handlebars|
        result = execute_methods(handlebars)
        result = result.slice(2..-3) #remove the handlebars
        string = string.sub(handlebars, result)
      end
      return string
    end
    
    def execute_methods(handlebars)
      string = handlebars
  
      match = string.match(INNERMOST_METHOD_REGEX)
      if match
        captures = match.captures
        to_replace = captures[0]
        method_name = captures[1]
        argument = captures[2]
        if self.respond_to?(method_name)
          result = self.public_send(method_name, argument)
          string = string.sub(to_replace, result)
          string = execute_methods(string)
        end
      end
  
      return string
    end
  
  end
end
