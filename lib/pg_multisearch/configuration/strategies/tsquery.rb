# frozen_string_literal: true

module PgMultisearch
  module Configuration::Strategies::Tsquery
    def prefix=(bool)
      check!(80_400, 'prefix') if bool

      self[:prefix] = bool
    end

    def tsquery_function=(fn)
      case (fn = fn.to_sym)
      when :plainto_tsquery      then check!(95_000, fn)
      when :phraseto_tsquery     then check!(96_000, fn)
      when :websearch_to_tsquery then check!(110_000, fn)
      when :to_tsquery           then nil
      else
        fn = :to_tsquery
      end

      self[:tsquery_function] = fn
    end
  end
end
