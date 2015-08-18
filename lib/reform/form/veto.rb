require "veto"
require "reform/validation"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Veto
  module Validations
    def build_errors
      Errors.new
    end

    module ClassMethods
      def validation_group_class
        Group
      end
    end

    def self.included(includer)
      includer.extend(ClassMethods)
    end

    class Group
      def initialize
        @validations = Class.new(Validator)
      end

      def validates(*args, &block)
        @validations.validates(*args, &block)
      end
      # TODO: ::validate, etc.

      def call(fields, errors, form) # FIXME.
        # private_errors = Reform::Form::Lotus::Errors.new # FIXME: damn, Lotus::Validator.validate does errors.clear.

        validator = @validations.new

        validator.valid?(form) # TODO: OpenStruct.new(@fields)


        # TODO: merge with AM.
        validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
          errors.add(name, *error)
        end
      end
    end

    require "veto"
    class Validator
      include Veto.validator
    end
  end

  class Errors
    extend Uber::Delegates

    def initialize(*args)
      @lotus_errors = Veto::Errors.new(*args)
    end

    delegates :@lotus_errors, :clear, :add, :empty?

    def each(&block)
      @lotus_errors.each(&block)
    end

    def merge!(errors, prefix)
      errors.each do |name, err|
        field = (prefix+[name]).join(".").to_sym

        next if @lotus_errors[field].any?

        @lotus_errors.add(field, *err) # TODO: use namespace feature in Lotus here!
      end
    end

    def messages
      return @lotus_errors.to_s
      errors = {}
      @lotus_errors.instance_variable_get(:@errors).each do |name, err|
        errors[name] ||= []
        errors[name] += err.map(&:to_s)
      end
      errors
    end

    # needed in simple_form, etc.
    def [](name)
      @lotus_errors.for(name)
    end
  end
end
