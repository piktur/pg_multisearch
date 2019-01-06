# frozen_string_literal: true

module PgMultisearch
  module Index
    raise ::NotImplementedError unless defined?(::ActiveRecord)

    class Base < ::ActiveRecord::Base
      extend  ClassMethods
      extend  Scopes
      include InstanceMethods

      self.table_name = meta.table_name

      # @!attribute [r] searchable
      #   @return [Indexable]
      belongs_to  :searchable,
                  polymorphic: true,
                  inverse_of:  :pg_multisearch_document
    end
  end
end
