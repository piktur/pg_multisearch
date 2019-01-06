# TODO

## Bug

* [ ] Ensure columns referenced by all strategies projected
* [ ] `Configuration::Rank#calculation` is not applied

* [ ] Refactor (Count query builder)[pg_multisearch/lib/pg_multisearch/index/relation/count.rb]
  - Store query fragments as curried Procs on the relation
* [ ] Threshold should be capable of filtering up to 3 strategies. It compares 2 currently.
* [ ] Handle tertiary strategies
* [ ] Decouple `tsheadline` from `tsearch` filter
* [ ] Refactor bound variable tracking and application to prepared statements
* [ ] `ts_rank({weights}::float4[], ...)` and `ts_rank_cd` should accept weight scale arg
* [ ] [Search.call](lib/pg_multisearch/search.rb) should accept and, if given, overload configuration at runtime
* [ ] Clarify `Index::Relation` identity; is it possible to cache against runtime options?
* [ ] Add `ts_headline` content field to data::jsonb; runtime concatenation introduces unnecessary complexity and is slower.
* [x] Ony select pk/fk when performing a JOIN. Since the query uses a CTE this is unnecessary.
* [x] Ensure aggregate index utilised when `searchable_type` present in WHERE clause. It is.
* [ ] Use exec_update rather than execute, or call on the `PGResult#clear`
* [ ] Supported PostgreSQL versions should be able to execute multi insert on rebuild
* [ ] exec ANALYZE on table after bulk update; stats should be refreshed

* [ ] Improve plugin interface and documentation
* [ ] Improve adapter interface, decouple from Rails and ActiveRecor
* [ ] Improve generator flexibility. The user should be able to customise the table schema
  - Add `--strategies` option or use existing plugins option to build only required columns and indices
  - Add `--index` option allowing the user to subclass [](lib/pg_multisearch/index/base.rb)

## Compatibility

* [ ] Remove Oj, use ActiveSupport::JSON or MultiJSON
* [ ] Ensure Kaminari and WillPaginate integration [Document Loader](/lib/pg_multisearch/plugins/document/index/relation/loader.rb)
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

* [ ] Refactor railtie re/load hooks
  - Ensure compatibility with Rails 4/5


[](activerecord-4.0.13/lib/active_record/relation.rb)
[](activerecord-4.0.13/lib/active_record/relation/query_methods.rb)
[](activerecord-4.0.13/lib/active_record/relation/calculations.rb)
[](activerecord-4.0.13/lib/active_record/querying.rb)
[](pg_search-1.0.6/spec/support/database.rb)
[](activerecord-4.0.13/lib/active_record/connection_adapters/postgresql_adapter.rb)
[](activerecord-4.0.13/lib/active_record/connection_adapters/postgresql/database_statements.rb)
