# frozen_string_literal: true

RSpec.describe PgMultisearch::Configuration do
  describe PgMultisearch::Configuration::Options do
    # A default configuration can be defined on application load
    # Subsequent defintions as in scope configuration can:
    # Nested config nodes
    #   inherit global defaults     #method(&block)
    #   or start clean              #method!(&block)
    # Config leaves
    #   simple accessor
    #     def attr=(val)
    #       self[:attr] = cast(val)
    #     end
    #     def attr
    #       self[:attr] 
    #     end
    describe '#against' do

    end

    describe '#associated_against' do

    end

    describe '#ignoring' do

    end

    describe '#order_within_rank' do

    end

    describe '#query' do

    end

    describe '#rank_by' do

    end

    describe '#strategies' do

    end

    describe '#weights' do

    end

    describe '#to_hash'
  end
end
