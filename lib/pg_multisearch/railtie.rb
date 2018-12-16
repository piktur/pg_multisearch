# frozen_string_literal: true

module PgMultisearch
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'pg_multisearch/tasks.rb'
    end

    generators do
      require 'pg_multisearch/generators'
    end

    config.after_initialize do
      content, header, dmetaphone = columns = %i(
        CONTENT_COLUMN
        HEADER_COLUMN
        DMETAPHONE_COLUMN
      ).map { |const| ::PgMultisearch::Index.const_get(const, false) }

      options = ::PgMultisearch.options

      options[:against] = options[:against] | columns

      (options[:using] ||= {}).tap do |features|
        (features[:tsearch] ||= {}).tap do |feature|
          feature[:tsvector_column] = Array(feature[:tsvector_column]) | [content]
          feature[:only] = Array(feature[:only]) | columns
        end

        (features[:dmetaphone] ||= {}).tap do |feature|
          feature[:dictionary] ||= 'simple'
          feature[:tsvector_column] = Array(feature[:tsvector_column]) | [dmetaphone]
          feature[:only] = Array(feature[:only]) | [dmetaphone]
        end

        (features[:trigram] ||= {}).tap do |feature|
          feature[:only] = Array(feature[:only]) | [header]
        end
      end
    end
  end
end
