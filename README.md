# DatabaseValidations

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

## validates_db_uniqueness_of

Supported databases: `postgresql`, `mysql` and `sqlite`.

### Pros and Cons

Advantages: 
- Provides true uniqueness on the database level because it handles race conditions cases properly.
- Check the existence of correct unique index at the boot time. Use `ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'` 
if you want to skip it in some cases.
- It's faster. See [Benchmark](https://github.com/toptal/database_validations#benchmark-code) section for details.

Disadvantages: 
- Cannot handle multiple validations at once because database raises only one error for all indexes per query.
    ```ruby
    class User < ActiveRecord::Base
      validates_db_uniqueness_of :email
      validates_db_uniqueness_of :name
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

List of supported options from `validates_uniqueness_of` validator: 

- `scope`: One or more columns by which to limit the scope of the uniqueness constraint.
- `message`: Specifies a custom error message (default is: "has already been taken").

**Keep in mind**: Even when we don't support `case_sensitive`, `allow_nil` and `allow_blank` options now, the following:

```ruby
validates_db_uniqueness_of :email
```

Is the same by default as the following 

```ruby
validates_uniqueness_of :email, allow_nil: true, allow_blank: false, case_sensitive: true
``` 

List of supported options for `PostgreSQL` only:

- `where`: Specify the conditions to be included as a <tt>WHERE</tt> SQL fragment to 
limit the uniqueness constraint lookup (e.g. <tt>where: "(status = 'active')"</tt>).
For backward compatibility, this will be converted automatically 
to <tt>conditions: -> { where("(status = 'active')") }</tt> for `valid?` method.

The list of options to add support:

- `case_sensitive`: Looks for an exact match. Ignored by non-text columns (`true` by default).
- `allow_nil`: If set to `true`, skips this validation if the attribute is `nil` (default is `false`).
- `allow_blank`: If set to `true`, skips this validation if the attribute is blank (default is `false`).
- `if`: Specifies a method, proc or string to call to determine if the validation should occur 
(e.g. <tt>if: :allow_validation</tt>, or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
proc or string should return or evaluate to a `true` or `false` value.
- `unless`: Specifies a method, proc or string to call to determine if the validation should not 
occur (e.g. <tt>unless: :skip_validation</tt>, or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). 
The method, proc or string should return or evaluate to a `true` or `false` value.

### Benchmark ([code](https://github.com/toptal/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb))

| Case                             | Validator                  | SQLite                                     | PostgreSQL                                 | MySQL                                      |
| -------------------------------- | -------------------------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| Save duplicate item only         | validates_db_uniqueness_of | 1.404k (±14.7%) i/s - 6.912k in 5.043409s  | 508.889 (± 2.8%) i/s - 2.550k in 5.015044s | 649.356 (±11.5%) i/s - 3.283k in 5.153444s |
|                                  | validates_uniqueness_of    | 1.505k (±14.6%) i/s - 7.448k in 5.075696s  | 637.017 (±14.1%) i/s - 3.128k in 5.043434s | 473.561 (± 9.7%) i/s - 2.352k in 5.021151s |
| Save unique item only            | validates_db_uniqueness_of | 3.241k (±18.3%) i/s - 15.375k in 5.014244s | 1.345k  (± 5.5%) i/s - 6.834k in 5.096706s | 1.439k  (±12.9%) i/s - 7.100k in 5.033603s |
|                                  | validates_uniqueness_of    | 2.002k (±10.9%) i/s - 9.900k in 5.018449s  | 667.100 (± 4.8%) i/s - 3.350k in 5.034451s | 606.334 (± 4.9%) i/s - 3.068k in 5.072587s |
| Each hundredth item is duplicate | validates_db_uniqueness_of | 3.534k (± 5.6%) i/s - 17.748k in 5.039277s | 1.351k  (± 6.5%) i/s - 6.750k in 5.017280s | 1.436k  (±11.6%) i/s - 7.154k in 5.062644s |
|                                  | validates_uniqueness_of    | 2.121k (± 6.8%) i/s - 10.653k in 5.049739s | 658.199 (± 6.1%) i/s - 3.350k in 5.110176s | 596.024 (± 6.7%) i/s - 2.989k in 5.041497s |

## Development

You need to have installed and running `postgresql` and `mysql`. 
And for each adapter manually create a database called `database_validations_test`. 

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `rake spec` to run the tests. You can also run `bin/console` for 
an interactive prompt that will allow you to experiment.

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
