# [PgMultisearch](http://github.com/piktur/pg_multisearch)

[![Build Status](https://travis-ci.com/piktur/pg_multisearch.svg?branch=master)](https://travis-ci.com/piktur/pg_multisearch)

PgMultisearch extends [pg_search](https://github.com/Casecommons/pg_search) providing better support for multi table search index.

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
