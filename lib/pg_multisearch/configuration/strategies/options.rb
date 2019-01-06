# frozen_string_literal: true

module PgMultisearch
  module Configuration
    module Strategies
      Options = ::Struct.new(*Strategies.strategies) do
        include Base

        defaults do |obj|

        end

        Strategies.strategies.each do |strategy|
          klass = "Strategies::#{::PgMultisearch.inflector.camelize(strategy.to_s)}"

          class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
            def #{strategy}
              fetch_or_store(:#{strategy}) { #{klass}.new(__meta__: __meta__) }
                .tap { |obj| yield(obj, __meta__) if block_given? }
            end
          RUBY
        end

        def to_hash
          h = {}
          members.each { |k| (v = self[k]) && h[k] = v.to_h }
          h
        end
        alias_method :to_h, :to_hash
      end
    end
  end
end
