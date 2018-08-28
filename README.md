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

**Note**: keep in mind, we don't check uniqueness validity through `valid?` method.
```ruby
original = User.create(email: 'email@mail.com')
dupe = User.new(email: 'email@mail.com')
dupe.valid?
# => true
dupe.save
# => false 
dupe.errors.messages
# => {:email=>["has already been taken"]} 
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

### Benchmark ([code](https://github.com/djezzzl/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb))

#### Saving only duplicates items ([code](https://github.com/djezzzl/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb#L56))

```
validates_db_uniqueness_of
                          1.487k (±10.1%) i/s -      7.425k in   5.053608s
validates_uniqueness_of
                          1.500k (±18.3%) i/s -      7.238k in   5.024355s
```

#### Saving only unique items ([code](https://github.com/djezzzl/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb#L63))

```
validates_db_uniqueness_of
                          3.558k (± 3.5%) i/s -     18.105k in   5.094799s
validates_uniqueness_of
                          2.031k (± 8.3%) i/s -     10.241k in   5.080059s
```

#### Each hundredth item is duplicate ([code](https://github.com/djezzzl/database_validations/blob/master/benchmarks/uniqueness_validator_benchmark.rb#L70))

```
validates_db_uniqueness_of
                          3.499k (± 4.8%) i/s -     17.628k in   5.050887s
validates_uniqueness_of
                          2.074k (± 8.6%) i/s -     10.388k in   5.063879s
```

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

Bug reports and pull requests are welcome on GitHub at https://github.com/djezzzl/database_validations. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected 
to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DatabaseValidations project’s codebases, issue trackers, chat rooms and mailing 
lists is expected to follow the [code of conduct](https://github.com/djezzzl/database_validations/blob/master/CODE_OF_CONDUCT.md).
