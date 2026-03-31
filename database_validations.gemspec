lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'database_validations/version'

Gem::Specification.new do |spec|
  spec.name          = 'database_validations'
  spec.version       = DatabaseValidations::VERSION
  spec.authors       = ['Evgeniy Demin']
  spec.email         = ['lawliet.djez@gmail.com']
  spec.summary       = 'Provide compatibility between database constraints
and ActiveRecord validations with better performance and consistency.'
  spec.description   = "ActiveRecord provides validations on app level but it won't guarantee the
consistent. In some cases, like `validates_uniqueness_of` it executes
additional SQL query to the database and that is not very efficient.

The main goal of the gem is to provide compatibility between database constraints
and ActiveRecord validations with better performance and consistency."
  spec.homepage      = 'https://github.com/toptal/database_validations'
  spec.license       = 'MIT'
  spec.files         = Dir['lib/**/*', 'config/**/*']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['default_lint_roller_plugin'] = 'RuboCop::DatabaseValidations::Plugin'

  spec.add_dependency 'activerecord', '>= 7.2.0'

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'db-query-matchers'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sqlite3'
end
