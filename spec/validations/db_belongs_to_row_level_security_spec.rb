RSpec.describe '.db_belongs_to with PostgreSQL row-level security' do
  # End to end for a foreign key violation that carries no `Key (...)=(...)` in its `DETAIL` line: see
  # `Rescuer.foreign_key_columns`.
  let(:role) { 'database_validations_rls_probe' }
  let(:connection) { ActiveRecord::Base.connection }
  let(:klass) { define_class(ActiveRecord::Base, :rls_members) { db_belongs_to :rls_parent } }

  before do
    define_database(postgresql_configuration)
    stub_const('RlsParent', Class.new(ActiveRecord::Base) { self.table_name = 'rls_parents' })

    can_create_roles = connection.select_value(
      'SELECT rolsuper OR rolcreaterole FROM pg_roles WHERE rolname = current_user'
    )
    skip 'needs a role that can create roles' unless can_create_roles

    connection.execute("DROP ROLE IF EXISTS #{role}")
    connection.execute("CREATE ROLE #{role}")

    ActiveRecord::Schema.define(version: 1) do
      create_table :rls_parents
      create_table :rls_members do |t|
        t.belongs_to :rls_parent, foreign_key: true
      end
    end

    # Row-level security on the table the key is on is what hides the key's values.
    %w[rls_parents rls_members].each do |table|
      connection.execute("GRANT SELECT, INSERT, UPDATE, DELETE ON #{table} TO #{role}")
      connection.execute("GRANT USAGE, SELECT ON SEQUENCE #{table}_id_seq TO #{role}")
      connection.execute("ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY")
      connection.execute("CREATE POLICY allow_all ON #{table} USING (true) WITH CHECK (true)")
    end
    connection.execute("SET ROLE #{role}")
  end

  after do
    connection.execute('RESET ROLE')
    connection.execute("DROP OWNED BY #{role}")
    connection.execute("DROP ROLE #{role}")
  end

  it 'is run under a role that row-level security applies to (the premise of the other examples)' do
    error = begin
      connection.execute('INSERT INTO rls_members (rls_parent_id) VALUES (-1)')
    rescue ActiveRecord::InvalidForeignKey => e
      e
    end

    expect(error.message).to include('violates foreign key constraint')
    expect(error.message).not_to match(/Key \(/)
  end

  it 'adds the error to the record instead of raising' do
    record = klass.create(rls_parent_id: -1)

    expect(record.errors.details).to eq(rls_parent: [{ error: :blank }])
  end

  it 'raises RecordInvalid from the bang methods' do
    expect { klass.create!(rls_parent_id: -1) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
