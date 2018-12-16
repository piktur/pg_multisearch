# frozen_string_literal: true

module PgMultisearch
  class Index < ::ActiveRecord::Base
    extend ::ActiveSupport::Autoload

    autoload :Builder
    autoload :Loader
    autoload :Pagination
    autoload :Preloader
    autoload :Rebuild
    autoload :Rebuilder

    CONTENT_COLUMN = 'content'
    HEADER_COLUMN = 'header'
    DMETAPHONE_COLUMN = 'dmetaphone'

    include ::PgSearch

    self.table_name = 'pg_search_documents'

    # @!attribute [r] searchable
    #   @return [ActiveRecord::Base]
    belongs_to  :searchable,
                polymorphic: true,
                inverse_of:  :pg_search_document

    require_relative './index/scope.rb'
    extend Scope

    # @return [Document::Base]
    def to_document
      ::Object.const_get(searchable_type, false).to_document(data || EMPTY_HASH, rank)
    end

    # @return [Float]
    def pg_search_rank
      self[:pg_search_rank]
    end
    alias rank pg_search_rank
  end
end
