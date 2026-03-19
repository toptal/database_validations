require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'active_record'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

def database_configurations
  configs = {}

  configs['postgresql'] = {
    'adapter' => 'postgresql',
    'database' => 'database_validations_test',
    'host' => ENV['DB_HOST'] || '127.0.0.1',
    'username' => ENV['DB_USER'] || 'database_validations',
    'password' => ENV['DB_PASSWORD'] || 'database_validations'
  }

  configs['mysql'] = {
    'adapter' => 'mysql2',
    'database' => 'database_validations_test',
    'host' => ENV['DB_HOST'] || '127.0.0.1',
    'username' => ENV['MYSQL_USER'] || 'root',
    'password' => ENV['MYSQL_PASSWORD'] || 'database_validations'
  }

  configs
end

include ActiveRecord::Tasks

DatabaseTasks.database_configuration = database_configurations
DatabaseTasks.db_dir = 'db'
DatabaseTasks.migrations_paths = []
DatabaseTasks.root = File.dirname(__FILE__)
DatabaseTasks.env = ENV.fetch('DB', 'postgresql')

task :environment do
  ActiveRecord::Base.configurations = database_configurations
  ActiveRecord::Base.establish_connection(DatabaseTasks.env.to_sym)
end

load 'active_record/railties/databases.rake'

namespace :db do
  namespace :all do
    desc 'Create both PostgreSQL and MySQL test databases'
    task :create do
      failures = []
      database_configurations.each do |name, config|
        puts "Creating #{name} database..."
        ActiveRecord::Tasks::DatabaseTasks.create(config)
      rescue StandardError => e
        failures << name
        warn "  Failed to create #{name}: #{e.message}"
      end
      abort "Failed to create: #{failures.join(', ')}" if failures.any?
    end

    desc 'Drop both PostgreSQL and MySQL test databases'
    task :drop do
      failures = []
      database_configurations.each do |name, config|
        puts "Dropping #{name} database..."
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
      rescue StandardError => e
        failures << name
        warn "  Failed to drop #{name}: #{e.message}"
      end
      abort "Failed to drop: #{failures.join(', ')}" if failures.any?
    end
  end
end
