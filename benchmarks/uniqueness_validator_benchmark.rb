require 'benchmark/ips'
require 'database_validations'
require_relative 'gc_suite'

[
  {
    adapter: 'sqlite3',
    database: ':memory:'
  },
  {
    adapter: 'postgresql',
    database: 'database_validations_test'
  },
  {
    adapter: 'mysql2',
    database: 'database_validations_test'
  }
].each do |database_configuration|
  ActiveRecord::Base.establish_connection(database_configuration)
  ActiveRecord::Schema.define(version: 1) do
    drop_table :entities, if_exists: true, force: :cascade

    create_table :entities do |t|
      t.integer :field
      t.index [:field], unique: true
    end
  end
  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.logger = nil

  class Entity < ActiveRecord::Base
    reset_column_information
  end

  class DbValidation < Entity
    validates_db_uniqueness_of :field
  end

  class AppValidation < Entity
    validates_uniqueness_of :field
  end

  # ===Benchmarks===
  suite = GCSuite.new
  field = 0
  Entity.create(field: field)

  Benchmark.ips do |x|
    x.config(suite: suite)

    x.report("#{database_configuration[:adapter]} only unique: validates_uniqueness_of") { field += 1; AppValidation.create(field: field) }
    x.report("#{database_configuration[:adapter]} only unique: validates_db_uniqueness_of") { field += 1; DbValidation.create(field: field) }

    x.report("#{database_configuration[:adapter]} each hundredth is a duplicate: validates_uniqueness_of") { field += 1; AppValidation.create(field: (field % 100 == 0 ? 0 : field)) }
    x.report("#{database_configuration[:adapter]} each hundredth is a duplicate: validates_db_uniqueness_of") { field += 1; DbValidation.create(field: (field % 100 == 0 ? 0 : field)) }

    x.report("#{database_configuration[:adapter]} only duplicates: validates_uniqueness_of") { AppValidation.create(field: 0) }
    x.report("#{database_configuration[:adapter]} only duplicates: validates_db_uniqueness_of") { DbValidation.create(field: 0) }
  end

  # Clear the DB
  ActiveRecord::Schema.define(version: 1) do
    drop_table :entities, if_exists: true, force: :cascade
  end
end
