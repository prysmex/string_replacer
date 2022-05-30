require "string_replacer/version"

module StringReplacer
  #
  # Wrapps a string with simple handlebar notation {{some_method()}} that may contain one or
  # more methods (helpers) that will be evaluated in a safe way when calling #replace
  #
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
      #
      # @return [String] name of registered helper
      def register_helper(name, &block)
        name = name.to_sym
        define_method(name, &block) #or define_singleton_method?
        @registered_helpers.push(name)
        name
      end
      
      # Unregisters a helper from class
      #
      # @return [Array] Remaining helpers
      def unregister_helper(name)
        name = name.to_sym
        undef_method name rescue false
        @registered_helpers = @registered_helpers - [name]
      end

    end
    
    # IMPORTANT! always keep in sync method name regex! [a-zA-Z0-9_]*
    # Regex used to search for handlebars and its most important features
    # by using the following named captures.
    #
    # 1. handelbars
    # 2. to_replace
    # 3. name
    # 4. arguments
    #
    # @example
    #   " {{capitalize(swapcase(hey))}} {{swapcase(user_name())}}".scan(INNERMOST_HELPER_REGEX)
    #   
    #   [
    #     [
    #       "{{capitalize(swapcase(hey))}}",    1) handlebars
    #       "capitalize(",
    #       "swapcase(hey)",                    2) to_replace
    #       "swapcase",                         3) swapcase
    #       "hey",                              4) arguments
    #       ")"
    #     ],
    #    [...]
    #   ]
    INNERMOST_HELPER_REGEX = /
      (?<handlebars>
        {{                          # opening double braces
        (?<before>                  # open none capture group everything before innermost helper
          \s*                       # allow any amount of spaces, for visual clarity
          [a-zA-Z0-9_]*             # helper name
          \(                        # open parenthesis
          (?=\s*[a-zA-Z0-9_]*\()    # ensure there are more inner helpers
        )*
        (?<to_replace>
          \s*                       # allow any amount of spaces, for visual clarity
          (?<name>
            [a-zA-Z0-9_]+           # innermost helper name
          )
          \(                        # parenthesis
          (?<arguments>
            [a-zA-Z0-9_.,'" |-]*       # innermost helper arguments
          )
          \)
          \s*                       # allow any amount of spaces, for visual clarity
        )
        (?<after>
          [) ]*                     # only allow closing parenthesis and spaces
        )
        }}
      )                             # closing double braces
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
    # If there is an error, execution stops and the error is added to @errors
    #
    # @return [String] with replaced handlebars
    def replace
      string = @string
      @errors = []
      handlebars_array = string.scan(INNERMOST_HELPER_REGEX).map(&:first)
      handlebars_array.each do |handlebars|
        begin
          result = replace_helpers_recursively(handlebars)
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

    # Same as #replace, but raises error if an error is raised during interpolation
    #
    # @return [String]
    def replace!
      @raise_errors = true
      replace
    ensure
      @raise_errors = false
    end

    # Checks if a helper exists
    #
    # @param [String,Symbol] name <description>
    # @return [Boolean] true if helper is registered
    def helper_exists?(name)
      name = name.to_sym
      self.class.registered_helpers.include?(name)
    end

    # @return [Boolean]
    def is_replaceable
      !string.scan(INNERMOST_HELPER_REGEX).empty?
    end

    private
    
    # Receives a single 'handlebars' and recusively executes helpers and replaces them
    # on the main string with the returned value
    #
    # @param [String] handlebars example: "{{capitalize(swapcase(hey))}}"
    # @return [String] replaced string, example: "{{Hey}}"
    def replace_helpers_recursively(handlebars)  
      match = handlebars.match(INNERMOST_HELPER_REGEX)
      return handlebars unless match
      
      captures = match.named_captures
      to_replace = captures['to_replace']
      helper_name = captures['name']
      argument = captures['arguments']

      if !self.helper_exists?(helper_name)
        raise NoMethodError.new("Unregistered helper '#{helper_name}'")
      end

      # call the method
      result = if argument == ''
        self.public_send(helper_name)
      else
        self.public_send(helper_name, argument)
      end
      handlebars = handlebars.sub(to_replace, result)
      replace_helpers_recursively(handlebars)
    end
  
  end
end
