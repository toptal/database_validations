require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'active_record'
require_relative 'config/database_config'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

DATABASE_CONFIGURATIONS = DatabaseConfig.load

include ActiveRecord::Tasks

DatabaseTasks.database_configuration = DATABASE_CONFIGURATIONS
DatabaseTasks.db_dir = 'db'
DatabaseTasks.migrations_paths = []
DatabaseTasks.root = File.dirname(__FILE__)
DatabaseTasks.env = ENV.fetch('DB', 'postgresql')

task :environment do
  ActiveRecord::Base.configurations = DATABASE_CONFIGURATIONS
  ActiveRecord::Base.establish_connection(DatabaseTasks.env.to_sym)
end

load 'active_record/railties/databases.rake'

namespace :db do
  namespace :all do
    desc 'Create both PostgreSQL and MySQL test databases'
    task :create do
      failures = []
      DATABASE_CONFIGURATIONS.each do |name, config|
        next if config['adapter'] == 'sqlite3'

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
      DATABASE_CONFIGURATIONS.each do |name, config|
        next if config['adapter'] == 'sqlite3'

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
