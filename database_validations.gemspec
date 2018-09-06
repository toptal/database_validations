lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "database_validations/version"

Gem::Specification.new do |spec|
  spec.name          = "database_validations"
  spec.version       = DatabaseValidations::VERSION
  spec.authors       = ["Evgeniy Demin"]
  spec.email         = ["lawliet.djez@gmail.com"]
  spec.summary       = %q{Provide compatibility between database constraints
and ActiveRecord validations with better performance and consistency.}
  spec.description   = %q{ActiveRecord provides validations on app level but it won't guarantee the
consistent. In some cases, like `validates_uniqueness_of` it executes
additional SQL query to the database and that is not very efficient.

The main goal of the gem is to provide compatibility between database constraints
and ActiveRecord validations with better performance and consistency.}
  spec.homepage      = "https://github.com/toptal/database_validations"
  spec.license       = "MIT"
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir['lib/**/*'] + %w[README.md LICENSE.txt]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 3.2", "< 6"

  spec.add_development_dependency "benchmark-ips", "~> 2.7"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "pg", "~> 1.1"
  spec.add_development_dependency "mysql2", "~> 0.5"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
