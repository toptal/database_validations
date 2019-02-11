# Changelog

## [0.8.6] - 11-02-19
### Improvements
- Refactor and slight performance improvement

## [0.8.5] - 05-02-19
### Bugs
- Fix a behavior for 3rd parties such as `simple_form`

## [0.8.4] - 06-02-19
### Bugs
- Fix a bug for `db_belongs_to`, validation should check `blank?` not `nil?`

## [0.8.3] - 05-02-19
### Bugs
- Fix bug for `db_belongs_to` when we skip other validations if the relation is missing

## [0.8.2] - 10-01-18
### Bugs
- Fix RuboCop cop for `validates_db_uniqueness_of` to catch `validates_uniqueness_of` definition too. 

## [0.8.1] - 09-01-18
### Features
- Add RuboCop cop for `db_belongs_to` and `validates_db_uniqueness_of`

## [0.8.0] - 30-11-18
### Features
- Add `db_belongs_to` 

## [0.7.3] - 2018-10-18
### Features
- Add support of `case_sensitive` option for `valid?` for `PostgreSQL`

## [0.7.2] - 2018-10-17
### Features
- Extend RSpec matcher to accept instance of model

## [0.7.1] - 2018-10-17
### Bugs
- Fix rake task issue for rails
- Adjust RSpec matcher to support `index_name` option

## [0.7.0] - 2018-10-16
### Features
- Add support of `index_name` option to `PostgreSQL` and `MySQL` databases
