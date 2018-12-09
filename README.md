# DatabaseValidations

[![Build Status](https://travis-ci.org/toptal/database_validations.svg?branch=master)](https://travis-ci.org/toptal/database_validations)
[![Gem Version](https://badge.fury.io/rb/database_validations.svg)](https://badge.fury.io/rb/database_validations)

ActiveRecord provides validations on app level but it won't guarantee the 
consistent. In some cases, like `validates_uniqueness_of` it executes 
additional SQL query to the database and that is not very efficient. 

The main goal of the gem is to provide compatibility between database constraints 
and ActiveRecord validations with better performance and consistency.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'database_validations'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install database_validations
    
## Example

Have a look at [example](example) application. 

## Why I should use this gem?

Because it provides faster solutions (see the composed benchmarks below) 
and ensures consistency of your database when ActiveRecord doesn't. 

## Composed [benchmarks](https://github.com/toptal/database_validations/blob/master/benchmarks/composed_benchmarks.rb)

| Case                                                                  | PostgreSQL                                 | MySQL                                      |
| --------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------ |
| Save only valid items (positive case)                                 | 381.818 (± 6.0%) i/s - 1.924k in 5.057491s | 293.304 (± 7.8%) i/s - 1.464k in 5.037224s |
|                                                                       |  1.003k (±12.3%) i/s - 4.984k in 5.075305s | 1.060k  (± 6.6%) i/s - 5.353k in 5.075530s |
| Each hundredth item is not valid (closer to life, but still specific) | 405.040 (± 3.0%) i/s - 2.052k in 5.071201s | 300.618 (± 2.0%) i/s - 1.508k in 5.018377s |
|                                                                       | 1.007k  (±15.5%) i/s - 4.876k in 5.013361s | 1.046k  (± 6.1%) i/s - 5.300k in 5.088503s |
| Save only invalid items (super worst case / impossible)               | 373.382 (±15.3%) i/s - 1.849k in 5.080908s | 294.326 (± 4.1%) i/s - 1.470k in 5.002983s |
|                                                                       | 705.731 (±17.1%) i/s - 3.444k in 5.048612s | 552.250 (± 8.0%) i/s - 2.800k in 5.108251s |

*The more you use it, the more you save!* (because default ActiveRecord methods increase the time).

## db_belongs_to

ActiveRecord's `belongs_to` has `optional: false` by default. That means each time you save your record 
it produces additional queries to check if the relation exists in the database. 
But it doesn't guarantee that your relation will be there after your request is executed. 
Here comes in handy `db_belongs_to`, it performs much faster and ensures real existence and has 
full back-compatibility with `belongs_to`, so it's easy to replace.

Supported databases: `PostgreSQL`, `MySQL`. 
*Note*: Unfortunately, `SQLite` raises poor error message by which we can't determine which exactly foreign key raises an error.

### Pros and Cons

Advantages:
- Provides true validation of relation existence because it uses foreign keys constrains.
- Checks the existence of correct foreign key at the boot time. Use `ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'`
if you want to skip in in some cases. E.g., when you run migrations.
- It's much faster. See benchmark section below for details. 
Spoiler: it's almost two times faster except the almost impossible worst case.

Disadvantages:
- Cannot handle multiple validations at once because database raises only one error per query.

### How it works?

We override `save` and `save!` methods where we rescue `ActiveRecord::InvalidForeignKey` and add proper errors
for compatibility.

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

### Configuration options

Full compatibility with `belongs_to` except polymorphic association. 

### Benchmark [code](https://github.com/toptal/database_validations/blob/master/benchmarks/db_belongs_to_benchmark.rb)

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

Supported databases: `PostgreSQL`, `MySQL` and `SQLite`.

### Pros and Cons

Advantages: 
- Provides true uniqueness on the database level because it handles race conditions cases properly.
- Checks the existence of correct unique index at the boot time. Use `ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'` 
if you want to skip it in some cases. E.g., when you run migrations.
- It's faster. See benchmark section below for details.

Disadvantages: 
- Cannot handle multiple validations at once because database raises only one error per query.
    ```ruby
    class User < ActiveRecord::Base
      validates_db_uniqueness_of :email, :name
    end
  
    original = User.create(name: 'name', email: 'email@mail.com')
    dupe = User.create(name: 'name', email: 'email@mail.com')
    # => false
    dupe.errors.messages
    # => {:name=>["has already been taken"]} 
    ```

### How it works?

We override `save` and `save!` methods where we rescue `ActiveRecord::RecordNotUnique` and add proper errors
for compatibility.

For `valid?` we use implementation from `validates_uniqueness_of` where we query the database.

### Usage

```ruby
class User < ActiveRecord::Base
  validates_db_uniqueness_of :email
end

original = User.create(email: 'email@mail.com')
dupe = User.create(email: 'email@mail.com')
# => false
dupe.errors.messages
# => {:email=>["has already been taken"]}
User.create!(email: 'email@mail.com')
# => ActiveRecord::RecordInvalid Validation failed: email has already been taken
```

### Configuration options

We want to provide full compatibility with existing `validates_uniqueness_of` validator. 

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

**Keep in mind**: `if`, `unless` and `case_sensitive` options are used only for `valid?` method. 

```ruby
class User < ActiveRecord::Base
  validates_db_uniqueness_of :email, if: -> { email && email_changed? }
end 

user = User.create(email: 'email@mail.com', field: 'field')
user.field = 'another'

user.valid? # Will not query the database
```

**Backward compatibility**: Even when we don't natively support `case_sensitive`, `allow_nil` and `allow_blank` options now, the following:

```ruby
validates_db_uniqueness_of :email
```

Is the same by default as the following 

```ruby
validates_uniqueness_of :email, allow_nil: true, allow_blank: false, case_sensitive: true
``` 

Complete `case_sensitive` replacement example (for `PostgreSQL` only):

```ruby
validates :slug, uniqueness: { case_sensitive: false, scope: :field }
```

Should be replaced by:

```ruby
validates_db_uniqueness_of :slug, index_name: :unique_index_with_field_lower_on_slug, case_sensitive: false
```

Options descriptions: 
- `scope`: One or more columns by which to limit the scope of the uniqueness constraint.
- `message`: Specifies a custom error message (default is: "has already been taken").
- `if`: Specifies a method or proc to call to determine if the validation should occur 
(e.g. `if: :allow_validation`, or `if: Proc.new { |user| user.signup_step > 2 }`). The method or
proc should return or evaluate to a `true` or `false` value.
- `unless`: Specifies a method or proc to call to determine if the validation should not 
occur (e.g. `unless: :skip_validation`, or `unless: Proc.new { |user| user.signup_step <= 2 }`). 
The method or proc should return or evaluate to a `true` or `false` value.
- `where`: Specify the conditions to be included as a `WHERE` SQL fragment to 
limit the uniqueness constraint lookup (e.g. `where: "(status = 'active')"`).
For backward compatibility, this will be converted automatically 
to `conditions: -> { where("(status = 'active')") }` for `valid?` method.
- `case_sensitive`: Looks for an exact match. Ignored by non-text columns (`true` by default).
- `allow_nil`: If set to `true`, skips this validation if the attribute is `nil` (default is `false`).
- `allow_blank`: If set to `true`, skips this validation if the attribute is blank (default is `false`).
- `index_name`: Allows to make explicit connection between validator and index. Used when gem can't automatically find index. 

### Benchmark ([code](https://github.com/toptal/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb))

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
And for each adapter manually create a database called `database_validations_test` accessible to your local user. 

Then, run `rake spec` to run the tests.

To check the conformance with the style guides, run:

    rubocop

To run benchmarks, run:

    ruby -I lib benchmarks/composed_benchmarks.rb

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, and then 
run `bundle exec rake release`, which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

[Bug reports](https://github.com/toptal/database_validations/issues) and [pull requests](https://github.com/toptal/database_validations/pulls) are welcome on GitHub. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected 
to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DatabaseValidations project’s codebases, issue trackers, chat rooms and mailing 
lists is expected to follow the [code of conduct](https://github.com/toptal/database_validations/blob/master/CODE_OF_CONDUCT.md).

## Authors

- [Evgeniy Demin](https://github.com/djezzzl)
