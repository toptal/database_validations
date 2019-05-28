source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in database_validations.gemspec
gemspec

group :test do
  gem 'rspec_junit_formatter', '~> 0.4.1'
end

eval(File.read(ENV['GEMFILE_PATH'])) if ENV['GEMFILE_PATH']
