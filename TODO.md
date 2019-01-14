# TODO

## Bug

* [-] Ensure columns referenced by all strategies projected
* [x] `Configuration::Rank#calculation` is not applied

* [ ] Application global config is not applied if option is defined in `Configuration::Base.defaults`. Application defaults should be applied to `Configuration::Scopes` before PgMultisearch defaults

## Incomplete

* [ ] `Index::Scopes#with_rank_gt` incomplete

## Revise

* [ ] Don't reuse `Strategies::Tsquery`, it should be okay to rebuld. We can however cache the parsed text input against a hash of the input to partially reducing the cost. In general we should try to limit coupling; the queries, filters and ranks should be independent of one another, the `Index::Relation` binds them together.
* [ ] Filter and Rank tsquery should not be reused, they must remain independent ie. it should be possible to apply weights when filtering but rank without the condition
* [ ] Query shouldn't be coupled to filter as rank may utilise columns other than those referenced by filter.
* [ ] Trigram should be ordered by lexeme position; Use `unnest` to order lexemes, currently pg_multisearch_words are in what seems to be alphabetical order. Unnest returns their actual position within the original document. Only available within 9.5 and up.
* [ ] Refactor (Count query builder)[pg_multisearch/lib/pg_multisearch/index/relation/count.rb]
  - Store query fragments as curried Procs on the relation
* [ ] Handle  strategies
  - [x] document yield params for Configuration::Rank#calculation. Yield all strategies and the ast to the `Rank::Base#calc` block. Otherwise they should be able to write the arel or sequel that they know.
  - [ ] Threshold should be capable of filtering up to 3 strategies. It compares 2 currently.
* [ ] Decouple `tsheadline` from `tsearch` filter
* [ ] Find a way to cast bound variable of type array when executing prepared statement. See `Filter::Base#by_type`
* [ ] Refactor bound variable tracking and application to prepared statements
* [ ] `ts_rank({weights}::float4[], ...)` and `ts_rank_cd` should accept weight scale arg
* [ ] [Search.call](lib/pg_multisearch/search.rb) should accept and, if given, overload configuration at runtime
* [ ] Clarify `Index::Relation` identity; is it possible to cache against runtime options?
* [x] Ony select pk/fk when performing a JOIN. Since the query uses a CTE this is unnecessary.
* [x] Ensure aggregate index utilised when `searchable_type` present in WHERE clause. It is.
* [ ] `Document::Base` should be read only

## Improvement

* [ ] Add `ts_headline` content field to data::jsonb; runtime concatenation introduces unnecessary complexity and is slower.
* [ ] Use exec_update rather than execute, or call on the `PGResult#clear`
* [ ] Supported PostgreSQL versions should be able to execute multi insert on rebuild
* [ ] exec ANALYZE on table after bulk update; stats should be refreshed
* [ ] plugin interface and documentation
* [ ] adapter interface, decouple from Rails and ActiveRecor
* [ ] generator flexibility. The user should be able to customise the table schema
  - Add `--strategies` option or use existing plugins option to build only required columns and indices
  - Add `--index` option allowing the user to subclass [](lib/pg_multisearch/index/base.rb)

## Compatibility

* [ ] Refactor railtie re/load hooks
  - Ensure compatibility with Rails 4/5
* [ ] Remove Oj, use ActiveSupport::JSON or MultiJSON
* [ ] Verify Kaminari and WillPaginate integration [Document Loader](/lib/pg_multisearch/plugins/document/index/relation/loader.rb)
* [ ] Compatibility ActiveRecord < 5
  - Add JSONB OID
  - Add searchable enum OID

  ```ruby
    module ActiveRecord::ConnectionAdapters::PostgreSQL
      module OID
        class Jsonb < Type::Json
          def type
            :jsonb
          end
        end

        class Enum < Type::Value # :nodoc:
          def type
            :enum
          end

          private

            def cast_value(value)
              value.to_s
            end
        end
      end

      NATIVE_DATABASE_TYPES[:jsonb] = { name: 'jsonb' }

      OID.register_type('jsonb', OID::Jsonb)
      # OID.register_type('searchable', OID::Enum)
    end
  ```


[](activerecord-4.0.13/lib/active_record/relation.rb)
[](activerecord-4.0.13/lib/active_record/relation/query_methods.rb)
[](activerecord-4.0.13/lib/active_record/relation/calculations.rb)
[](activerecord-4.0.13/lib/active_record/querying.rb)
[](pg_search-1.0.6/spec/support/database.rb)
[](activerecord-4.0.13/lib/active_record/connection_adapters/postgresql_adapter.rb)
[](activerecord-4.0.13/lib/active_record/connection_adapters/postgresql/database_statements.rb)
