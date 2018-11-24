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

    create_table :companies

    create_table :users_1 do |t|
      t.belongs_to :company
    end

    create_table :users_2 do |t|
      t.belongs_to :company, foreign_key: true
    end
  end
  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.logger = nil

  class Company < ActiveRecord::Base
  end

  class Users1 < ActiveRecord::Base
    self.table_name = :users_1
    belongs_to :company, optional: false
  end

  class Users2 < ActiveRecord::Base
    self.table_name = :users_2
    db_belongs_to :company
  end

  # ===Benchmarks===
  suite = GCSuite.new
  company = Company.create!

  # ===Save using ID===
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('belongs_to') { Users1.create(company_id: company.id) }
    x.report('db_belongs_to') { Users2.create(company_id: company.id) }
  end

  # ===Each hundredth is not found===
  field = 0
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('belongs_to') { field +=1; field % 100 == 0 ? Users1.create(company_id: -1) : Users1.create(company_id: company.id) }
    x.report('db_belongs_to') { field += 1; field % 100 == 0 ? Users2.create(company_id: -1) : Users2.create(company_id: company.id) }
  end

  # ===Not found===
  Benchmark.ips do |x|
    x.config(suite: suite)
    x.report('belongs_to') { Users1.create(company_id: -1) }
    x.report('db_belongs_to') { Users2.create(company_id: -1) }
  end

  # Clear the DB
  ActiveRecord::Schema.define(version: 2) do
    drop_table :users_1, if_exists: true, force: :cascade
    drop_table :users_2, if_exists: true, force: :cascade
    drop_table :companies, if_exists: true, force: :cascade
  end
end
