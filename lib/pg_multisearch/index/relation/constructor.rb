# frozen_string_literal: true

module PgMultisearch
  class Index::Relation
    class Constructor
      # @param (see #initialize)
      def self.[](config)
        new(config).call
      end

      # @param [Configuration::Base] config
      def initialize(config)
        @config = config
      end

      # @return [Relation]
      def call(*) # rubocop:disable AbcSize
        relation = Index::Relation.new(config, Array(config.filter_by).compact)

        relation.extend(WithHighlight) if highlight?
        relation.extend(prepared_statement? ? AsPreparedStatement : AsStatement)

        return relation unless rank?

        rank_by(*config.rank_by)

        relation.extend(WithRank)

        relation.rank_constructor = rank_constructor.curry[*rank_constructor_args]

        relation
      end

      private

        # @!attribute [r] config
        #   @return [Configuration::Base]
        attr_reader :config

        # @!attribute [r] rank_options
        #   @return [Hash]
        attr_reader :rank_options

        # @!attribute [r] primary
        # @!attribute [r] secondary
        # @!attribute [r] tertiary
        # @return [Symbol]
        attr_reader :primary, :secondary, :tertiary

        # @!attribute [r] polymorphic
        #   @return [Hash]
        attr_reader :polymorphic

        # @!attribute [r] threshold
        #   @return [Float]
        attr_reader :threshold

        # @return [Proc]
        def rank_constructor
          lambda do |klass, strategies, options, ext, relation|
            klass.allocate.tap do |obj|
              obj.extend(*ext) if ext.present?
              obj.send(:initialize, relation, strategies, options)
            end
          end
        end

        # @return [Array]
        def rank_constructor_args # rubocop:disable AbcSize
          if polymorphic?
            rank_options[:polymorphic] = polymorphic
            [Rank::Polymorphic, nil, rank_options, rank_extensions]
          elsif threshold?
            rank_options[:threshold] = threshold
            [Rank::Threshold, [primary, *secondary, *tertiary], rank_options, rank_extensions]
          else
            [Rank::Base, [primary, *secondary, *tertiary], rank_options, rank_extensions]
          end
        end

        # @return [Array<Module>]
        def rank_extensions
          [].tap do |arr|
            arr << (prepared_statement? ? AsPreparedStatement : AsStatement)
          end
        end

        # @param [Symbol] primary
        # @param [Symbol] secondary
        # @param [Symbol] tertiary
        #
        # @option [Hash] options :polymorphic Apply ranking alogorithm per indexable type
        def rank_by(*strategies, polymorphic: nil, threshold: nil, **rank_options)
          @primary, @secondary, @tertiary = strategies
          @polymorphic  = polymorphic
          @threshold    = threshold
          @rank_options = rank_options

          self
        end

        # @return [Symbol]
        def tsearch
          ::PgMultisearch::Strategies::Tsearch.strategy_name
        end

        # @return [Boolean]
        def rank?
          config.rank_by.present?
        end

        # @return [Boolean]
        def prepared_statement?
          config.prepared_statement
        end

        # @return [Boolean]
        def highlight?
          config.filter_by.include?(tsearch) &&
            config.strategies[tsearch][:highlight].present?
        end

        # @return [Boolean]
        def polymorphic?
          polymorphic.present?
        end

        # @return [Boolean]
        def threshold?
          threshold # || secondary.present?
        end
    end
  end
end
