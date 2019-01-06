# frozen_string_literal: true

module PgMultisearch
  # @todo Implement cache mechanism utilising `Concurrent::Map`
  class Index::Cache < ::BasicObject
    attr_reader :cache

    def initialize
      @cache = {}
    end

    def [](*args)
      cache[args.hash]
    end

    def []=(*args, value)
      cache[args.hash] = value
    end

    def fetch_or_store(*args)
      cache[args.hash] ||= yield
    end

    def clear
      cache.clear
    end
  end
end
