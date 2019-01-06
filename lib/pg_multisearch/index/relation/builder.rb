# frozen_string_literal: true

module PgMultisearch
  module Index
    class Relation
      class Builder
        # @!attribute [r] relation
        #   @return [Relation] The internal relation handler
        attr_reader :relation

        # @!attribute [r] scope
        #   @return [ActiveRecord::Relation] The current scope
        attr_reader :scope

        # @param [Configuration::Base] config
        def initialize(config)
          @config   = config
          @relation = Index::Relation[config]
        end

        # @param [Index::Base, ActiveRecord::Relation] current_scope
        #   Receives the current scope; existing refinements SHOULD BE preserved.
        # @param [Hash] options Runtime options
        #
        # @option (see Loader#initialize)
        #
        # @return [ActiveRecord::Relation]
        def call(current_scope, options) # rubocop:disable MethodLength
          return none(current_scope) if options[:input].blank?

          self.options = options
          self.scope   = current_scope

          relation.call(scope, options) do |relation|
            relation.select_append(
              *index.projections(
                :searchable_type,
                :searchable_id
              )
            )

            yield(relation) if block_given?
          end

          relation.scope
        end

        # @overload self.scope = current_scope
        #   @param [ActiveRecord::Relation] current_scope
        #   @return [ActiveRecord::Relation]
        def scope=(current_scope)
          @scope = with_table_alias(current_scope)
        end

        protected

          # @!attribute [r] config
          #   @return [Configuration::Base]
          attr_reader :config

          # @!attribute [rw] options
          #   Replaced per {#call}
          #   @return [Hash] Runtime options
          attr_accessor :options

        private

          # @return [Index::Base] The PgMultisearch::Index
          def index
            config.index
          end

          # @!method none(index)
          #   @param [Index::Base] index
          #   @return [ActiveRecord::Relation] if ActiveRecord::VERSION::MAJOR < 4
          #   @return [ActiveRecord::NullRelation] if ActiveRecord::VERSION::MAJOR >= 4
          if ::ActiveRecord::VERSION::MAJOR < 4
            def none(current_scope)
              @scope = with_table_alias(current_scope.select('NULL'.freeze).where('FALSE'.freeze))
            end
          else
            def none(current_scope)
              @scope = with_table_alias(current_scope.none)
            end
          end

          # @param [ActiveRecord::Relation] scope
          #
          # @return [ActiveRecord::Relation]
          def with_table_alias(scope)
            klass = scope.klass
            return klass if klass.included_modules.include?(WithTableAlias)

            scope.extend(WithTableAlias)
          end
      end
    end
  end
end
