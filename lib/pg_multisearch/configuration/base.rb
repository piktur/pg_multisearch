# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Base
      # @!method new(options)
      #   @!scope class
      #   @param [Hash] options

      # Redefines the constructor so that it accepts keyword arguments.
      # {Undefined} is assigned to member if missing from kwargs.
      # {#fetch} and {#fetch_or_store} utilse {Undefined} to distinguish an explicit falsey value
      # from one that is as yet untouched.
      #
      # {Undefined} allows {PgMultisearch.config} defaults to be applied to per {Scopes}
      # configuration to avoid unnecessary repetition.
      def self.included(base)
        base.extend ClassMethods

        kwargs = base.members.map { |k| "#{k}: Undefined".freeze }.join(', '.freeze)
        args   = base.members.join(', ')

        base.class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def initialize(#{kwargs}, __meta__: Index::Base.meta)
            super(#{args})

            self.__meta__ = __meta__

            instance_eval(&self.class.defaults)
          end
        RUBY
      end
      private_class_method :included

      module ClassMethods
        def defaults(&block)
          @defaults ||= block_given? ? block : NOOP
        end
      end

      # @!attribute [rw] __meta__
      #   @return [Index::Meta]
      attr_accessor :__meta__
      protected :__meta__

      # @param [Symbol] member
      #
      # @yieldparam [self] config
      #
      # @return [Object] Yields self to the block and returns the result
      def fetch(member)
        Undefined.default(self[member]) { yield(self) }
      end

      # @param [Symbol] member
      #
      # @yieldparam [self] config
      #
      # @return [Object]
      #   Yields self to the block and assigns the result to `member`.
      #   If frozen, yields self to the block and returns the result without assignment.
      def fetch_or_store(member)
        fetch(member) do
          if frozen? # too late
            yield(self)
          else
            send("#{member}=".to_sym, yield(self))
          end
        end
      end

      # @param [Array<Symbol, Integer>] path
      #
      # @return [Object] The value at `path` or, if `path` unreachable, the result of the block
      def dig(*path, &block)
        path.reduce(self) do |obj, i|
          case obj
          when Base, ::Hash then obj.fetch(i, &block)
          when ::Array      then obj[i] || (block_given? ? yield : nil)
          end
        end
      end

      # @param [Array<Integer, Symbol>] members
      #
      # @return [Array<Object>]
      def values_at(*members)
        members.map { |e| self[e] }
      end

      # @param [Hash, Options] other
      #
      # @return [Options] Deep union replaces nil or empty values with a copy from other
      def |(other)
        members.each do |k|
          v = other[k]

          case v
          when Base
            send(k) | v
          else
            unless v.nil? || other == Undefined
              case self[k]
              when EMPTY_ARRAY, EMPTY_HASH, EMPTY_SET, Undefined
                self[k] = (v.duplicable? && v.clone) || v
              end
            end
          end
        end

        self
      end

      def to_hash
        h = {}
        members.each { |k| (v = send(k)) && h[k] = v }
        h
      end
      alias to_h to_hash

      # @return [self]
      def finalize!
        members.each do |k|
          case v = self[k]
          when Base      then v.finalize!
          when Undefined then self[k] = nil
          end
        end

        validate!

        freeze
      end

      # @return [self]
      def freeze
        members.each { |k| !(v = self[k]).is_a?(Module) && v.freeze }

        super
      end

      def validate!; end

      private

        # @return [Adapters::AST]
        def ast
          Adapters.ast
        end

        def postgresql_version
          ::PgMultisearch.postgresql_version
        end

        # @param (see PgMultisearch.check!)
        #
        # @return [void]
        def check!(*args)
          ::PgMultisearch.check!(*args)
        end

        def invalid!(k, v)
          raise(Configuration::ValidationError.new(k, v))
        end

        # @return [String]
        def __path__(*args)
          [
            ::PgMultisearch.inflector
              .underscore(self.class.name)
              .tap { |str| str['pg_multisearch/configuration/'] = EMPTY_STRING }
              .tr('/'.freeze, '.'.freeze),
            *args
          ].join('.')
        end

        # @return [Options] Returns a deep copy of self
        def initialize_copy(source)
          super(source)

          members
            .map { |k| [k, source[k]] }
            .each { |(k, v)| self[k] = v.duplicable? ? v.clone : v }

          self
        end
    end
  end
end
