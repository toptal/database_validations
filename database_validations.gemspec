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
  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.2.0'

  spec.add_development_dependency 'benchmark-ips', '~> 2.7'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.60'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.30'
  spec.add_development_dependency 'sqlite3', '~> 1.3'
end
