# frozen_string_literal: true

module PgMultisearch
  module Adapters
    extend ::ActiveSupport::Autoload

    autoload :Arel
    autoload :AST
    autoload :Sequel

    # @raise [UnsupportedAdapterError]
    #
    # @return [Module]
    def self.adapter
      if defined?(::ActiveRecord)
        Adapters::Arel
      elsif defined?(::Sequel)
        raise NotImplementedError, '@todo Implement Sequel::SQL AST interface'
        Adapters::Sequel
      else
        raise UnsupportedAdapterError, UNSUPPORTED_ADAPTER_MSG
      end
    end

    # @return [AST]
    def self.ast
      @ast ||= AST.new(adapter)
    end

    module Adapter
      def self.included(base)
        base.extend(ClassMethods)
      end
      private_class_method :included

      module ClassMethods
        # @return [AST]
        def ast
          @ast ||= Adapters.ast
        end
      end

      # @return [AST]
      def ast
        self.class.ast
      end
    end
  end
end
