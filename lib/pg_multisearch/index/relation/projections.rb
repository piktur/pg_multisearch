# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Projections
      include ::PgMultisearch.adapter
      include ::Enumerable

      # @!attribute [rw] table
      #   @return [ast.Table]
      attr_accessor :table

      # @!attribute [rw] all
      #   @return [Set]
      attr_accessor :all
      alias projections all

      def initialize(table, *projections)
        self.table = table
        self.all   = projections.map { |(column, aliaz)| qualified(column, aliaz) }.to_set
      end

      # @param [Projections, Enumerable] enum
      #
      # @return [self]
      def merge(enum)
        enum = enum.is_a?(Projections) ? enum.unqualfied : enum
        all.merge(enum.map { |(column, aliaz)| qualified(column, aliaz) })

        self
      end

      # @param (see #qualified)
      #
      # @return [self]
      def <<(other)
        all << case other
        when ast.Node, ast.Attribute then qualified(other)
        when ::Array                 then qualified(*other)
        else qualified(other)
        end

        self
      end
      alias add <<

      # @return [Set<ast.Attribute>]
      #   A new Set containing the union of {#all} and `other`
      def |(other)
        all | other
      end
      alias union |

      # @return [ast.Attribute]
      def qualified(column, aliaz = nil)
        case column
        when ast.Attribute
          column = column.name
        when ast.SqlLiteral
          column = column.to_s
        when ast.Node
          return column
        end

        aliaz ? table[column].as(aliaz) : table[column]
      end

      # @return [Array<Object, Object>]
      def unqualified(obj) # rubocop:disable AbcSize
        case obj
        when ::Array                             then obj.map { |col| unqualifed(col) }
        when ast.nodes.As                        then [obj.left, obj.right]
        when ast.nodes.TableAlias, ast.Attribute then [obj.name]
        when ast.SqlLiteral                      then [obj.to_s]
        when ast.Node                            then [obj]
          # [
          #   case obj.left
          #   when ast.Attribute
          #     obj.left.name
          #   when ast.Node
          #     obj.left
          #   end,
          #   obj.right
          # ]
        else [obj]
        end
      end

      def each(&block)
        all.each(&block)
      end

      # @return [Array<ast.Attribute>]
      def to_a
        all.to_a
      end
      alias to_ary to_a

      # @return [Set<ast.Attribute>]
      alias to_set all
    end
  end
end
