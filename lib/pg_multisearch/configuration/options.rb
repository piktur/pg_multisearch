# frozen_string_literal: true

module PgMultisearch
  module Configuration
    Options = ::Struct.new(
      :against,
      :filter_by,
      :index,
      :ignoring,
      :order_within_rank,
      :prepared_statement,
      :rank_by,
      :strategies,
      :weights
    ) do
      include Base

      defaults do |obj|
        obj.against  = EMPTY_ARRAY
        obj.ignoring = EMPTY_ARRAY
        obj.weights  = __meta__.weights
      end

      alias_method :columns, :against

      def against=(arr)
        self[:against] = Array(arr)
      end

      def ignoring=(arr)
        self[:ignoring] = Array(arr)
      end

      def rank_by
        fetch_or_store(:rank_by) { Rank.new(__meta__: __meta__) }
          .tap { |obj| yield(obj, __meta__) if block_given? }
      end

      def filter_by
        fetch_or_store(:filter_by) { Filter.new(__meta__: __meta__) }
          .tap { |obj| yield(obj, __meta__) if block_given? }
      end

      def strategies
        fetch_or_store(:strategies) { Strategies::Options.new(__meta__: __meta__) }
          .tap { |obj| yield(obj, __meta__) if block_given? }
      end

      def weights=(arr)
        self[:weights] = Array(arr) & __meta__.weights # Filter invalid weights from input
      end

      # @todo Strategies should add their requirements to the projected columns; allowing the user
      #   to specify columns will be error prone. Don't do this.
      #
      # @raise [ConfigurationError] if referenced columns missing
      #
      # @return [void]
      def validate!
        err = :invalid
        errors = []

        all_strategies = [filter_strategies, rank_strategies].each do |arr|
          ref = __meta__.projections(*arr)

          msg = catch(err) do
            arr.each do |e|
              msg = catch(err) do
                strategy = strategies.fetch(e) do
                  throw(err, "unknown strategy: #{e.inspect}")
                end

                msg = catch(err) do
                  next unless (diff = (ref - strategy.only)).present?

                  throw(err, "unreferenced column: #{diff.inspect}")
                end
              end
            end

            next
          end

          errors.push(msg) if msg
        end.reduce(&:|).presence

        required = all_strategies ? __meta__.projections(*all_strategies) : EMPTY_ARRAY

        return true unless errors.present? || (required - against).present?

        raise(
          ConfigurationError,
          "#{INVALID_COLUMN_SELECTION_MSG}#{errors.join("\n  * ")}"
        )
      end

      def to_hash
        super.tap do |h|
          h[:strategies] = strategies.to_h
          h[:rank_by]    = rank_by.to_a
          h[:filter_by]  = filter_by.to_a
        end
      end
      alias_method :to_h, :to_hash

      private

        def filter_strategies
          return EMPTY_ARRAY unless filter_by.present?

          filter_by.values_at(:primary, :secondary, :tertiary).compact
        end

        def rank_strategies
          return EMPTY_ARRAY unless rank_by.present?

          if rank_by.polymorphic.present?
            rank_by.polymorphic.values.flatten.compact
          else
            rank_by.values_at(:primary, :secondary, :tertiary).compact
          end
        end
    end
  end
end
