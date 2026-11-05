RSpec.describe 'Adapter.foreign_key_error_column' do
  def build_error(message:, sql: nil)
    error = ActiveRecord::InvalidForeignKey.new(message)
    error.set_query(sql, []) if sql
    error
  end

  describe DatabaseValidations::Adapters::PostgresqlAdapter do
    it 'extracts column from error message' do
      error = build_error(
        message: 'PG::ForeignKeyViolation: ERROR:  insert or update on table "db_belongs_users" violates ' \
                 'foreign key constraint "fk_rails_abc123" DETAIL:  Key (company_id)=(-1) is not present in table "companies".'
      )
      expect(described_class.foreign_key_error_column(error)).to eq(['company_id'])
    end

    it 'extracts every column of a composite key' do
      error = build_error(
        message: 'PG::ForeignKeyViolation: ERROR:  insert or update on table "db_belongs_users" violates ' \
                 'foreign key constraint "fk_tenant_company" DETAIL:  Key (tenant_id, company_id)=(2, 1) is not ' \
                 'present in table "companies".'
      )
      expect(described_class.foreign_key_error_column(error)).to eq(%w[tenant_id company_id])
    end

    it 'extracts the table the violated key is on' do
      error = build_error(
        message: 'PG::ForeignKeyViolation: ERROR:  insert or update on table "tenant_users" violates ' \
                 'foreign key constraint "fk_tenant_company" DETAIL:  Key (tenant_id, company_id)=(2, 1) is not ' \
                 'present in table "companies".'
      )
      expect(described_class.foreign_key_error_table(error)).to eq('tenant_users')
    end
  end

  describe DatabaseValidations::Adapters::MysqlAdapter do
    it 'extracts column from error message' do
      error = build_error(
        message: 'Mysql2::Error: Cannot add or update a child row: a foreign key constraint fails ' \
                 '(`test`.`db_belongs_users`, CONSTRAINT `fk_rails_abc123` FOREIGN KEY (`company_id`) ' \
                 'REFERENCES `companies` (`id`))'
      )
      expect(described_class.foreign_key_error_column(error)).to eq(['company_id'])
    end

    it 'extracts the table the violated key is on' do
      error = build_error(
        message: 'Mysql2::Error: Cannot add or update a child row: a foreign key constraint fails ' \
                 '(`test`.`db_belongs_users`, CONSTRAINT `fk_rails_abc123` FOREIGN KEY (`company_id`) ' \
                 'REFERENCES `companies` (`id`))'
      )
      expect(described_class.foreign_key_error_table(error)).to eq('db_belongs_users')
    end
  end

  describe DatabaseValidations::Adapters::SqliteAdapter do
    it 'extracts the table from the INSERT or UPDATE statement' do
      insert = build_error(message: 'FOREIGN KEY constraint failed',
                           sql: 'INSERT INTO "db_belongs_users" ("company_id") VALUES (?)')
      update = build_error(message: 'FOREIGN KEY constraint failed',
                           sql: 'UPDATE "db_belongs_users" SET "company_id" = ? WHERE "id" = ?')
      expect(described_class.foreign_key_error_table(insert)).to eq('db_belongs_users')
      expect(described_class.foreign_key_error_table(update)).to eq('db_belongs_users')
      expect(described_class.foreign_key_error_table(build_error(message: 'FOREIGN KEY constraint failed'))).to be_nil
    end

    it 'extracts column from single-column INSERT SQL' do
      error = build_error(
        message: 'SQLite3::ConstraintException: FOREIGN KEY constraint failed',
        sql: 'INSERT INTO "db_belongs_users" ("company_id") VALUES (?) RETURNING "id"'
      )
      expect(described_class.foreign_key_error_column(error)).to eq(['company_id'])
    end

    it 'extracts all columns from multi-column INSERT SQL' do
      error = build_error(
        message: 'SQLite3::ConstraintException: FOREIGN KEY constraint failed',
        sql: 'INSERT INTO "db_belongs_users" ("company_id", "department_id") VALUES (?, ?) RETURNING "id"'
      )
      expect(described_class.foreign_key_error_column(error)).to eq(%w[company_id department_id])
    end
  end
end
