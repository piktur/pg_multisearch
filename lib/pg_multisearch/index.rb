# frozen_string_literal: true

module PgMultisearch
  module Index
    extend ::ActiveSupport::Autoload

    autoload :Base
    autoload :Cache
    autoload :ClassMethods
    autoload :InstanceMethods
    autoload :Meta
    autoload :Rebuild
    autoload :Rebuilder
    autoload :Relation
    autoload :Scopes

    # @return [Meta]
    def self.meta
      Base.meta
    end
  end
end
