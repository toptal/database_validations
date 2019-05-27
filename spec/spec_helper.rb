require 'bundler/setup'
require 'database_validations'

# Use this constant to enable Rails 5+ compatible specs
RAILS_5 = ActiveRecord::VERSION::MAJOR >= 5

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def clear_database!(configuration)
    ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=0;' if configuration[:adapter] == 'mysql2'
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table, force: :cascade)
    end
    ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=1;' if configuration[:adapter] == 'mysql2'
  end

  def postgresql_configuration
    {
      adapter: 'postgresql',
      database: 'database_validations_test',
      host: ENV['DB_HOST'] || '127.0.0.1',
      username: ENV['DB_USER'],
      password: ENV['DB_PASSWORD']
    }
  end

  def mysql_configuration
    {
      adapter: 'mysql2',
      database: 'database_validations_test',
      host: ENV['DB_HOST'] || '127.0.0.1',
      username: ENV['DB_USER'],
      password: ENV['DB_PASSWORD']
    }
  end

  def sqlite_configuration
    {
      adapter: 'sqlite3',
      database: ':memory:'
    }
  end
end
