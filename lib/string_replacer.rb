require "string_replacer/version"

module StringReplacer
  class Replacer

    #initialize class instance variable
    instance_variable_set('@registered_helpers', [])

    #class methods
    class << self
      attr_accessor :registered_helpers

      def inherited(subclass)
        #support subclassing
        subclass.instance_variable_set('@registered_helpers', self.registered_helpers)
        super
      end

      # Registers a helper to allow its usage.
      # @return [String] name of registered helper
      def register_helper(name, &block)
        name = name.to_sym
        define_method(name, &block) #or define_singleton_method?
        @registered_helpers.push(name)
        name
      end
      
      # Unregisters a helper from class
      # @return [Array] Remaining helpers
      def unregister_helper(name)
        name = name.to_sym
        undef_method name rescue false
        @registered_helpers = @registered_helpers - [name]
      end

    end
    
    # always keep in sync method name regex! [a-zA-Z0-9_]*
    INNERMOST_METHOD_REGEX = /
      (?<handlebars>
        {{                          # opening double braces
        (?<before>                  # open none capture group everything before innermost method
          \s*                       # allow any amount of spaces, for visual clarity
          [a-zA-Z0-9_]*             # method name
          \(                        # open parenthesis
          (?=\s*[a-zA-Z0-9_]*\()    # ensure there are more inner methods
        )*
        (?<to_replace>
          \s*                       # allow any amount of spaces, for visual clarity
          (?<name>
            [a-zA-Z0-9_]+           # innermost method name
          )
          \(                        # parenthesis
          (?<arguments>
            [a-zA-Z0-9_. |-]*      # innermost method arguments
          )
          \)
          \s*                       # allow any amount of spaces, for visual clarity
        )
        (?<after>
          [) ]*                       # only allow closing parenthesis and spaces
        )
        }}
      )                          # closing double braces
    /x
  
    attr_reader :string
    attr_reader :passed_data
    attr_reader :errors
  
    def initialize(string, passed_data = {})
      raise TypeError.new("first argument must be a String, passed #{string.class}") unless string.is_a?(String)
      raise TypeError.new("first argument must be a Hash, passed #{string.class}") unless passed_data.is_a?(Hash)

      @string = string
      @passed_data = passed_data
    end
    
    # Executes the logic to recursively replace all handlebars with registered helpers
    # If there is an error, execution stops and is returned
    # @return [String] with replaced handlebars
    def replace
      string = @string
      @errors = []
      string.scan(INNERMOST_METHOD_REGEX).map(&:first).each do |handlebars|
        begin
          result = execute_methods_recursively(handlebars)
          result = result.slice(2..-3) #remove the handlebars
          string = string.sub(handlebars, result)
        rescue => exception
          msg = exception.message + " while interpolating '#{handlebars}'"
          new_exception = exception.class.new(msg)
          @errors.push(new_exception)
          raise new_exception if @raise_errors
        end
      end
      return string
    end

    def replace!
      @raise_errors = true
      replace
    ensure
      @raise_errors = false
    end

    def method_is_whitelisted?(name)
      name = name.to_sym
      self.class.registered_helpers.include?(name)
    end

    private
    
    def execute_methods_recursively(handlebars)
      string = handlebars
  
      match = string.match(INNERMOST_METHOD_REGEX)
      if match
        captures = match.named_captures
        to_replace = captures['to_replace']
        method_name = captures['name']
        argument = captures['arguments']

        if !self.method_is_whitelisted?(method_name)
          raise NoMethodError.new("Unregistered helper '#{method_name}'")
        end

        # run the method
        result = if argument == ''
          self.public_send(method_name)
        else
          self.public_send(method_name, argument)
        end
        string = string.sub(to_replace, result)
        string = execute_methods_recursively(string)
      end
  
      return string
    end
  
  end
end
