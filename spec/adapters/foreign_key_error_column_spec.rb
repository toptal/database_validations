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
  end

  describe DatabaseValidations::Adapters::SqliteAdapter do
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
