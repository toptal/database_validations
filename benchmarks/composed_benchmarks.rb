require 'benchmark/ips'
require 'database_validations'
require_relative 'gc_suite'

[
  {
    adapter: 'postgresql',
    database: 'database_validations_test'
  },
  {
    adapter: 'mysql2',
    database: 'database_validations_test',
    username: 'root'
  }
].each do |database_configuration|
  ActiveRecord::Base.establish_connection(database_configuration)
  ActiveRecord::Schema.define(version: 1) do
    drop_table :users_1, if_exists: true, force: :cascade
    drop_table :users_2, if_exists: true, force: :cascade
    drop_table :companies, if_exists: true, force: :cascade
    drop_table :countries, if_exists: true, force: :cascade

    create_table :companies
    create_table :countries

    create_table :users_1 do |t|
      t.string :email
      t.string :full_name
      t.belongs_to :country
      t.belongs_to :company
      t.index :email
      t.index :full_name
    end

    create_table :users_2 do |t|
      t.string :email
      t.string :full_name
      t.belongs_to :country, foreign_key: true
      t.belongs_to :company, foreign_key: true
      t.index :email, unique: true
      t.index :full_name, unique: true
    end
  end
  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.logger = nil

  class Company < ActiveRecord::Base
  end

  class Country < ActiveRecord::Base
  end

  class Users1 < ActiveRecord::Base
    self.table_name = :users_1

    validates_uniqueness_of :email
    validates_uniqueness_of :full_name

    belongs_to :company, optional: false
    belongs_to :country, optional: false
  end

  class Users2 < ActiveRecord::Base
    self.table_name = :users_2

    validates_db_uniqueness_of :email
    validates_db_uniqueness_of :full_name

    db_belongs_to :company
    db_belongs_to :country
  end

  # ===Benchmarks===
  suite = GCSuite.new
  company = Company.create!
  country = Country.create!
  field = 0

  # ===Save only valid===
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('old way') { field += 1; Users1.create(company_id: company.id, country_id: country.id, full_name: field.to_s, email: field.to_s) }
    x.report('new way') { field += 1; Users2.create(company_id: company.id, country_id: country.id, full_name: field.to_s, email: field.to_s) }
  end

  # ===Each hundredth is invalid===
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('old way') { field += 1; field % 100 == 0 ? Users1.create(company_id: -1, country_id: -1, full_name: 'invalid', email: 'invalid') : Users1.create(company_id: company.id, country_id: country.id, full_name: field.to_s, email: field.to_s) }
    x.report('new way') { field += 1; field % 100 == 0 ? Users2.create(company_id: -1, country_id: -1, full_name: 'invalid', email: 'invalid') : Users2.create(company_id: company.id, country_id: country.id, full_name: field.to_s, email: field.to_s) }
  end

  # ===Save only invalid===
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('old way') { Users1.create(company_id: -1, country_id: -1, full_name: 'invalid', email: 'invalid') }
    x.report('new way') { Users2.create(company_id: -1, country_id: -1, full_name: 'invalid', email: 'invalid') }
  end

  # Clear the DB
  ActiveRecord::Schema.define(version: 2) do
    drop_table :users_1, if_exists: true, force: :cascade
    drop_table :users_2, if_exists: true, force: :cascade
    drop_table :companies, if_exists: true, force: :cascade
    drop_table :countries, if_exists: true, force: :cascade
  end
end
