# DatabaseValidations

[![Build Status](https://travis-ci.org/toptal/database_validations.svg?branch=master)](https://travis-ci.org/toptal/database_validations)
[![Gem Version](https://badge.fury.io/rb/database_validations.svg)](https://badge.fury.io/rb/database_validations)

DatabaseValidations helps you to keep the database consistency with better performance. 
Right now, it supports only ActiveRecord.

*The more you use the gem, the more performance increase you have. Try it now!* 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'database_validations'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install database_validations
```
    
Have a look at [example](example) application for details.

## db_belongs_to

Supported databases are `PostgreSQL` and `MySQL`.  
**Note**: Unfortunately, `SQLite` raises a poor error message 
by which we can not determine exact foreign key which raised an error.

### Usage

```ruby
class User < ActiveRecord::Base
  db_belongs_to :company
end

user = User.create(company_id: nil)
# => false
user.errors.messages
# => {:company=>["must exist"]} 
```

### Problem

ActiveRecord's `belongs_to` has `optional: false` by default. Unfortunately, this
approach does not ensure existence of the related object. For example, we can skip 
validations or remove the related object after we save the object. After that, our
database becomes inconsistent because we assume the object has his relation but it 
does not.  

`db_belongs_to` solves the problem using foreign key constraints in the database 
also providing backward compatibility with nice validations errors.

### Pros and Cons

**Advantages**:
- Ensures relation existence because it uses foreign keys constraints.
- Checks the existence of proper foreign key constraint at the boot time.
Use `ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'` if you want to 
skip it in some cases. (For example, when you run migrations.)
- It's almost two times faster because it skips unnecessary SQL query. See benchmarks 
below for details.

**Disadvantages**:
- Cannot handle multiple database validations at once because database 
raises only one error per query.

### Configuration options

| Option name   | PostgreSQL | MySQL |
| ------------- | :--------: | :---: |
| class_name    | +          | +     |
| foreign_key   | +          | +     |
| foreign_type  | -          | -     |
| primary_key   | +          | +     |
| dependent     | +          | +     |
| counter_cache | +          | +     |
| polymorphic   | -          | -     |
| validate      | +          | +     |
| autosave      | +          | +     |
| touch         | +          | +     |
| inverse_of    | +          | +     |
| optional      | -          | -     |
| required      | -          | -     |
| default       | +          | +     |

### Benchmarks ([code](benchmarks/db_belongs_to_benchmark.rb))

| Case                                                                      | Relation      | PostgreSQL                                 | MySQL                                      |
| ------------------------------------------------------------------------- | ------------- | ------------------------------------------ | ------------------------------------------ |
| Save existing in DB item (positive case)                                  | belongs_to    | 679.869 (±37.4%) i/s - 2.945k in 5.326013s | 628.873 (±18.3%) i/s - 3.009k in 5.057690s |
|                                                                           | db_belongs_to | 990.386 (±27.0%) i/s - 4.440k in 5.033655s | 1.256k  (±14.8%) i/s - 6.188k in 5.064498s |
| Save only non-existing* item (super worst case / impossible)              | belongs_to    | 966.079 (±13.6%) i/s - 4.830k in 5.110996s | 714.486 (±10.2%) i/s - 3.588k in 5.085503s |
|                                                                           | db_belongs_to | 516.709 (±16.8%) i/s - 2.541k in 5.040354s | 498.942 (± 7.8%) i/s - 2.475k in 5.001812s |
| Each hundredth item is non-existing* (closer to life, but still specific) | belongs_to    | 830.240 (±10.6%) i/s - 4.104k in 5.019347s | 728.572 (±13.7%) i/s - 3.588k in 5.085377s |
|                                                                           | db_belongs_to | 1.311k  (±19.4%) i/s - 6.222k in 5.040586s | 1.320k  (±11.0%) i/s - 6.600k in 5.073114s |

* Non-existing item is a row with ID = -1

## validates_db_uniqueness_of

Supported databases are `PostgreSQL`, `MySQL` and `SQLite`.

### Usage

```ruby
class User < ActiveRecord::Base
  validates_db_uniqueness_of :email
  # The same as following:
  # validates_uniqueness_of :email, allow_nil: true, allow_blank: false, case_sensitive: true  
end

original = User.create(email: 'email@mail.com')
dupe = User.create(email: 'email@mail.com')
# => false
dupe.errors.messages
# => {:email=>["has already been taken"]}
User.create!(email: 'email@mail.com')
# => ActiveRecord::RecordInvalid Validation failed: email has already been taken
```

Complete `case_sensitive` replacement example (for `PostgreSQL` only):

```ruby
validates :slug, uniqueness: { case_sensitive: false, scope: :field }
```

Should be replaced by:

```ruby
validates_db_uniqueness_of :slug, index_name: :unique_index, case_sensitive: false, scope: :field
```

### Problem

Unfortunately, ActiveRecord's `validates_uniqueness_of` approach does not ensure 
uniqueness. For example, we can skip validations or create two records in parallel 
queries. After that, our database becomes inconsistent because we assume some uniqueness
over the table but it has duplicates.  

`validates_db_uniqueness_of` solves the problem using unique index constraints 
in the database also providing backward compatibility with nice validations errors.

### Pros and Cons

Advantages: 
- Ensures uniqueness because it uses unique constraints.
- Checks the existence of proper unique index at the boot time. 
Use `ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'` 
if you want to skip it in some cases. (For example, when you run migrations.)
- It's two times faster in average because it skips unnecessary SQL query. See benchmarks 
below for details.

Disadvantages: 
- Cannot handle multiple database validations at once because database raises 
only one error per query.

### Configuration options 

| Option name    | PostgreSQL | MySQL | SQLite |
| -------------- | :--------: | :---: | :----: |
| scope          | +          | +     | +      |
| message        | +          | +     | +      |
| if             | +          | +     | +      |
| unless         | +          | +     | +      |
| index_name     | +          | +     | -      |
| where          | +          | -     | -      |
| case_sensitive | +          | -     | -      |
| allow_nil      | -          | -     | -      | 
| allow_blank    | -          | -     | -      | 

### Benchmark ([code](benchmarks/uniqueness_validator_benchmark.rb))

| Case                             | Validator                  | SQLite                                     | PostgreSQL                                 | MySQL                                      |
| -------------------------------- | -------------------------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| Save duplicate item only         | validates_db_uniqueness_of | 1.404k (±14.7%) i/s - 6.912k in 5.043409s  | 508.889 (± 2.8%) i/s - 2.550k in 5.015044s | 649.356 (±11.5%) i/s - 3.283k in 5.153444s |
|                                  | validates_uniqueness_of    | 1.505k (±14.6%) i/s - 7.448k in 5.075696s  | 637.017 (±14.1%) i/s - 3.128k in 5.043434s | 473.561 (± 9.7%) i/s - 2.352k in 5.021151s |
| Save unique item only            | validates_db_uniqueness_of | 3.241k (±18.3%) i/s - 15.375k in 5.014244s | 1.345k  (± 5.5%) i/s - 6.834k in 5.096706s | 1.439k  (±12.9%) i/s - 7.100k in 5.033603s |
|                                  | validates_uniqueness_of    | 2.002k (±10.9%) i/s - 9.900k in 5.018449s  | 667.100 (± 4.8%) i/s - 3.350k in 5.034451s | 606.334 (± 4.9%) i/s - 3.068k in 5.072587s |
| Each hundredth item is duplicate | validates_db_uniqueness_of | 3.534k (± 5.6%) i/s - 17.748k in 5.039277s | 1.351k  (± 6.5%) i/s - 6.750k in 5.017280s | 1.436k  (±11.6%) i/s - 7.154k in 5.062644s |
|                                  | validates_uniqueness_of    | 2.121k (± 6.8%) i/s - 10.653k in 5.049739s | 658.199 (± 6.1%) i/s - 3.350k in 5.110176s | 596.024 (± 6.7%) i/s - 2.989k in 5.041497s |

## Testing (RSpec)

Add `require database_validations/rspec/matchers'` to your `spec` file.

### validate_db_uniqueness_of

Example: 

```ruby
class User < ActiveRecord::Base
  validates_db_uniqueness_of :field, message: 'duplicate', where: '(some_field IS NULL)', scope: :another_field, index_name: :unique_index
end

describe 'validations' do
  subject { User }
  
  it { is_expected.to validate_db_uniqueness_of(:field).with_message('duplicate').with_where('(some_field IS NULL)').scoped_to(:another_field).with_index(:unique_index) }
end
```

## Development

You need to have installed and running `postgresql` and `mysql`. 
And for each adapter manually create a database called `database_validations_test` accessible by your local user. 

Then, run `rake spec` to run the tests.

To check the conformance with the style guides, run:

```bash
rubocop
```

To run benchmarks, run:

```bash
ruby -I lib benchmarks/composed_benchmarks.rb
```

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, and then 
run `bundle exec rake release`, which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

[Bug reports](https://github.com/toptal/database_validations/issues) 
and [pull requests](https://github.com/toptal/database_validations/pulls) are 
welcome on GitHub. This project is intended to be a safe, welcoming space for 
collaboration, and contributors are expected to adhere 
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DatabaseValidations project’s codebases, issue trackers, chat rooms and mailing 
lists is expected to follow the [code of conduct](https://github.com/toptal/database_validations/blob/master/CODE_OF_CONDUCT.md).

## Authors

- [Evgeniy Demin](https://github.com/djezzzl)

## Contributors

- [Filipp Pirozhkov](https://github.com/pirj)
