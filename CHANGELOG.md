# Changelog

- Add `rescue: :default|:always` option to `DbUniquenessValidator`.

## [1.0.1]
### Fixes

- Add support of Ruby 3. Thanks [John Duff](https://github.com/jduff) for the contribution.

## [1.0.0]
### Fixes

- Remove deprecation warning when `connection_config` is used in Rails 6.1 (Use connection_db_config instead). Thanks [Alfonso Uceda](https://github.com/AlfonsoUceda) for the contribution.

## [0.9.4] - 30-09-20
### Fixes

- Respect `validate: false` option when using `save/save!` for Rails 5+. Thanks [Arkadiy Zabazhanov](https://github.com/pyromaniac) for the contribution.

## [0.9.3] - 24-09-20
### Improvements

- Add support of different `mode` to `DbUniquenessValidator`. Thanks [Arkadiy Zabazhanov](https://github.com/pyromaniac) for the contribution.

## [0.9.2] - 16-09-20
### Improvements

- Fix a warning message from newest Ruby version 

## [0.9.1] - 24-06-20
### Improvements

- Fix support of newest MySQL version
- Add case sensitive option to `validate_db_uniqueness_of` RSpec matcher

## [0.9.0] - 28-07-19
### Improvements

- Change the way of storing database validations
- Improve performance
- Refactor
- New syntax sugar

## [0.8.10] - 21-02-19
### Improvements
- Internal improvements 
- We raise an error if `scope` or `where` options are missed for the `validates_db_uniqueness_of`

## [0.8.9] - 13-02-19
### Bugs
- Hot-fix for `validate_db_uniqueness_of` RSpec matcher

## (removed) [0.8.8] - 13-02-19 
### Bugs
- Hot-fix for `validates_db_uniqueness_of`

## (removed) [0.8.7] - 13-02-19
### Improvements
- Refactor and performance improvement

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
