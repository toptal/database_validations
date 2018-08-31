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
- Check the existence of correct unique index at the boot time.
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

This list of options are from `validates_uniqueness_of` validator: 

- `scope`: One or more columns by which to limit the scope of the uniqueness constraint.
- `message`: Specifies a custom error message (default is: "has already been taken").
- `conditions`: Specify the conditions to be included as a <tt>WHERE</tt> SQL fragment to 
limit the uniqueness constraint lookup (e.g. <tt>conditions: -> { where(status: 'active') }</tt>).
- `case_sensitive`: Looks for an exact match. Ignored by non-text columns (`true` by default).
- `allow_nil`: If set to `true`, skips this validation if the attribute is `nil` (default is `false`).
- `allow_blank`: If set to `true`, skips this validation if the attribute is blank (default is `false`).
- `if`: Specifies a method, proc or string to call to determine if the validation should occur 
(e.g. <tt>if: :allow_validation</tt>, or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
proc or string should return or evaluate to a `true` or `false` value.
- `unless`: Specifies a method, proc or string to call to determine if the validation should not 
occur (e.g. <tt>unless: :skip_validation</tt>, or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). 
The method, proc or string should return or evaluate to a `true` or `false` value.

**Note**: only few options are supported now: `scope`.

### Benchmark ([code](https://github.com/toptal/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb))

| Case                             | Validator                  | SQLite                                     | PostgreSQL                                 | MySQL                                      |
| -------------------------------- | -------------------------- | ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| Save duplicate item only         | validates_db_uniqueness_of | 1.605k (± 8.4%) i/s - 7.975k in 5.010751s  | 497.935 (± 4.6%) i/s - 2.499k in 5.029835s | 637.607 (±12.1%) i/s - 3.136k in 5.012077s |
|                                  | validates_uniqueness_of    | 1.606k (±17.9%) i/s - 7.866k in 5.092134s  | 636.891 (±13.2%) i/s - 3.168k in 5.083220s | 470.443 (±11.5%) i/s - 2.352k in 5.088618s |
| Save unique item only            | validates_db_uniqueness_of | 3.544k (± 4.5%) i/s - 17.808k in 5.035887s | 885.103 (±30.8%) i/s - 4.004k in 5.066538s | 1.292k  (±15.8%) i/s - 6.424k in 5.108884s |
|                                  | validates_uniqueness_of    | 1.976k (±10.9%) i/s - 9.917k in 5.081734s  | 475.022 (±25.7%) i/s - 2.223k in 5.044149s | 586.996 (± 5.8%) i/s - 2.964k in 5.066596s |
| Each hundredth item is duplicate | validates_db_uniqueness_of | 3.330k (± 9.7%) i/s - 16.512k in 5.016920s | 1.055k  (±24.3%) i/s - 4.905k in 5.060765s | 1.408k  (± 5.1%) i/s - 7.038k in 5.011026s |
|                                  | validates_uniqueness_of    | 1.929k (±10.4%) i/s - 9.633k in 5.055946s  | 587.146 (±11.4%) i/s - 2.925k in 5.060540s | 522.770 (±19.3%) i/s - 2.394k in 5.012263s |

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
