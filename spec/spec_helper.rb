require 'bundler/setup'
require 'database_validations'
require 'shared/raise_index_not_found'
require 'db-query-matchers'

# Use this constant to enable Rails 5+ compatible specs
RAILS_5 = ActiveRecord::VERSION::MAJOR >= 5

DBQueryMatchers.configure do |config|
  config.schemaless = true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def clear_database!(configuration)
  ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=0;' if configuration[:adapter] == 'mysql2'
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table, force: :cascade)
  end
  ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=1;' if configuration[:adapter] == 'mysql2'
end

def define_database(configuration)
  ActiveRecord::Base.establish_connection(configuration)
  ActiveRecord::Schema.verbose = false

  clear_database!(configuration)
end

def define_table(table_name = :entities, &block)
  ActiveRecord::Schema.define(version: 1) do
    create_table table_name do |t|
      block.call(t)
    end
  end
end

def define_class(parent = ActiveRecord::Base, table_name = :entities, &block)
  Class.new(parent) do |klass|
    self.table_name = table_name

    def self.model_name
      ActiveModel::Name.new(self, nil, 'temp')
    end

    reset_column_information

    klass.instance_exec(&block) if block_given?
  end
end

def rescue_error
  yield
rescue ActiveRecord::RecordInvalid => e
  e.message
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

def postgresql_postgis_configuration
  {
    adapter: 'postgis',
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
