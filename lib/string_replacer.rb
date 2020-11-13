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

    end

    HANDLEBARS_REGEX = /{{.*?}}/
    INNERMOST_METHOD_REGEX = /{{.*?\b((\w+)\(((?=[^(]*?\)).*?)\))[) ]*}}/
  
    attr_reader :string
    attr_reader :passed_data
    attr_reader :errors
  
    def initialize(string, passed_data = {})
      @string = string
      @passed_data = passed_data
    end
    
    # Executes the logic to recursively replace all handlebars with registered helpers
    # If there is an error, execution stops and is returned
    # @return [String] with replaced handlebars
    def replace
      string = @string
      @errors = []
      string.scan(HANDLEBARS_REGEX).each do |handlebars|
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
  
      inner_method = string.match(INNERMOST_METHOD_REGEX)
      if inner_method
        captures = inner_method.captures
        to_replace = captures[0]
        method_name = captures[1]
        argument = captures[2]

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
