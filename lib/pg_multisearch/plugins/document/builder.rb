# frozen_string_literal: true

module PgMultisearch
  module Document
    class Builder < Index::Builder
      def apply(*, &block)
        super do |scope, builder|
          scope = scope
            .extend(Load)
            .select(
              "#{builder.quoted_table_name}.data",
              "#{builder.quoted_table_name}.searchable_type"
            )

          scope = scope.instance_exec(scope, builder, &block) if block_given?

          scope
        end
      end

      module Load
        def load(*args)
          Document::Loader.new(self, *args).to_a
        end
      end
    end
  end
end

require_relative './loader.rb'
