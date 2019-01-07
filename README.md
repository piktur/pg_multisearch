# [PgMultisearch](http://github.com/piktur/pg_multisearch)

[![Build Status](https://travis-ci.com/piktur/pg_multisearch.svg?branch=master)](https://travis-ci.com/piktur/pg_multisearch)

PgMultisearch provides **Full Text Search** capabilities against a global search index.

Inspired by and improves upon [`pg_search`'s](https://github.com/Casecommons/pg_search) [multi search](https://github.com/Casecommons/pg_search#multi-search) feature.

## Install

### Rails

```bash
  bin/rails g pg_multisearch:install Search \
  --types Organisation Product Interview Post Move Person \
  --use '{ "age": { "column": "provenance" }, "document": { "index": true } }'
```

## Configuration

```ruby
# config/initializers/pg_multisearch.rb

require 'pg_multisearch'

# Configure defaults. Defaults will be applied to each scope when missing.
PgMultisearch.configure do |defaults, index|
  plugin(:document)
  plugin(:suggestions)
  plugin(:age, column: 'provenance')

  defaults.against            = index.projections(:tsearch, :date, :dmetaphone, :trigram)
  defaults.ignoring           = :accents
  defaults.prepared_statement = true
  defaults.strategies do |strategies|
    strategies.age do |age|
      age.only = index.projections(:date)
    end

    strategies.dmetaphone do |dmetaphone|
      dmetaphone.any_word         = false
      dmetaphone.dictionary       = 'simple'
      dmetaphone.negation         = true
      dmetaphone.normalization    = 32
      dmetaphone.only             = index.projections(:dmetaphone)
      dmetaphone.prefix           = true
      dmetaphone.tsquery_function = :to_tsquery
      dmetaphone.tsrank_function  = :ts_rank
      dmetaphone.tsvector_column  = index.projections(:dmetaphone)
      dmetaphone.weights          = index.weights[0]
    end

    strategies.trigram do |trigram|
      trigram.word_similarity = false
    end

    strategies.tsearch do |tsearch|
      tsearch.any_word         = false
      tsearch.dictionary       = 'english'
      tsearch.negation         = true
      tsearch.normalization    = 32
      tsearch.only             = index.projections(:tsearch)
      tsearch.prefix           = true
      tsearch.tsquery_function = :to_tsquery
      tsearch.tsrank_function  = :ts_rank
      tsearch.tsvector_column  = index.projections(:tsearch)
    end
  end
end

# Configure `PgMultisearch::Index` scopes
Search.configure do |config, index| # rubocop:disable BlockLength
  # The default scope
  config.search do |scope|
    scope.filter_by do |filter|
      filter.primary   = index.strategy(:tsearch)
      filter.secondary = index.strategy(:dmetaphone) # Sound alike
      filter.tertiary  = index.strategy(:trigram)    # Fuzzy
    end

    scope.rank_by do |rank|
      # Apply
      rank.calculation = lambda { |primary, secondary, tertiary, ast|
        ast.group(primary + ast.group(secondary * 0.2)) / 2
      }

      # Calculates the average of three scores
      rank.primary   = index.strategy(:tsearch)
      rank.secondary = index.strategy(:trigram)
      rank.tertiary  = index.strategy(:dmetaphone)

      # Refine the result set
      rank.threshold = 0.3

      # Apply rules per Indexable type
      rank.polymorphic = {
        # Ranks non qualified types by age (according to a date stored within the configured date column)
        :default                  => index.strategy(:age),
        # Calculates the average of two scores for records of type Organisation and Person
        [%w(Organisation Person)] => index.strategies(
          :tsearch, # primary
          :trigram  # secondary
        )
      }
    end

    scope.strategies do |strategies|
      strategies.age do |age|

      end

      strategies.tsearch do |tsearch|
        tsearch.highlight do |highlight|
          # Build the highlightable document from the denormalized data
          highlight.document do |strategy, ast, table|
            ast.fn.jsonb_fields_to_text(table[index.projection(:data)], ['field1', 'field2'])
          end
          # Or specify the fields to use
          highlight.fields         = %w(title overview)
          highlight.min_words      = 15
          highlight.max_words      = 35
          highlight.max_fragments  = 0
          highlight.short_words    = 3
          highlight.start_sel      = '<b>'
          highlight.stop_sel       = '</b>'
        end
      end
    end
  end

  # Configure suggestions
  config.suggestions do |scope|
    scope.filter_by do |filter|
      filter.primary = index.strategy(:dmetaphone) # index.strategy(:trigram)
    end

    scope.rank_by do |rank|
      rank.primary = index.strategy(:dmetaphone) # index.strategy(:trigram)
    end

    scope.strategies do |strategies|
      strategies.dmetaphone do |dmetaphone|
        dmetaphone.any_word = true
        dmetaphone.prefix   = true
      end

      strategies.trigram do |trigram|
        trigram.word_similarity = true
      end
    end
  end
end
```

## Example

```ruby
  class Search
    include ::PgMultisearch::Search
  end

  params  = {
    'search' => 'query',
    'type' => 'Organisation'
  }
  options = {
    scope_name: :search,
    preload:    true,
    threshold:  0.6,
    weights:    %w(A B)
  }

  # Initialize the Search delegator with request paramters and options
  search = Search.call(params, options) # => #<Search>

  Search.call(params, scope_name: :suggestions, limit: 10).to_a

  # Apply further refinements to the scope
  search = Search.call(params, options) do |current_scope, builder|
    current_scope
      .where(%{ data ->> 'country' IN ('Saturn') })
      .where(%{ data @> '{"name":"von"}'::jsonb })
      .where(type: %w(Oblong))
      .page(page)
  end

  # Materialize the relation
  search.to_a

  # or Handle loading yourself
  search.load do |relation|
    relation.connection.select_values(relation.arel.to_sql, relation.klass, bind_params)

    # or

    res = relation.connection.execute(relation.arel.to_sql)
    tuples = res.values
    res.clear
    tuples
  end
```

## Index

Rebuild `bin/rake pg_multisearch:rebuild[model,schema]`

## [TODO](TODO.md)

## Development

Specs are defined within [`/spec`](/spec). Please submit relevant specs with your Pull Request.

To run tests:

- Install [`Ruby >= 2.2.2`](https://www.ruby-lang.org/en/documentation/installation/)
- Create a local test database `pg_multisearch_test` PostgreSQL
- Copy `spec/support/database.example.yml` to `spec/support/database.yml` and enter local credentials for the test database(s)
- Install development dependencies using `bundle`
- Run tests `bundle exec rspec`

We recommend to test large changes against multiple versions of Ruby and multiple dependency sets.
Supported combinations are configured in `.travis.yml`. We provide some Rake tasks to help with this:

- Install development dependencies using `bundle exec rake matrix:install`
- Run tests `bundle exec rake matrix:spec`

Note that we have configured `Travis CI` to automatically run tests in all supported Ruby versions and dependency sets after each push. We will only merge pull requests after a green Travis build.
