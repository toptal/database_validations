RSpec.describe '.validates_db_uniqueness_of with PostgreSQL row-level security' do
  # PostgreSQL leaves the `DETAIL:  Key (...)=(...) already exists.` line out of a unique violation on a table
  # that the current role is subject to row-level security on, because the values could belong to a row the role
  # cannot see. Such an error can only be matched by the name of the index.
  let(:role) { 'database_validations_rls_probe' }
  let(:connection) { ActiveRecord::Base.connection }

  before do
    define_database(postgresql_configuration)

    can_create_roles = connection.select_value(
      'SELECT rolsuper OR rolcreaterole FROM pg_roles WHERE rolname = current_user'
    )
    skip 'needs a role that can create roles' unless can_create_roles

    connection.execute("DROP ROLE IF EXISTS #{role}")
    connection.execute("CREATE ROLE #{role}")

    define_table(:rls_entities) do |t|
      t.string :name
      t.index :name, unique: true, name: 'index_rls_entities_on_name'
    end
    define_table(:rls_scoped_entities) do |t|
      t.string :name
      t.string :scope_key
      t.index %i[scope_key name], unique: true, name: 'index_rls_scoped_entities_on_scope_key_and_name'
    end

    %w[rls_entities rls_scoped_entities].each do |table|
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
    connection.execute("INSERT INTO rls_entities (name) VALUES ('taken')")

    error = begin
      connection.execute("INSERT INTO rls_entities (name) VALUES ('taken')")
    rescue ActiveRecord::RecordNotUnique => e
      e
    end

    expect(error.message).to include('unique constraint "index_rls_entities_on_name"')
    expect(error.message).not_to match(/Key \(/)
  end

  shared_examples 'turns the collision into a validation error' do
    it 'adds the error to the record instead of raising' do
      klass.create!(attrs)

      record = klass.create(attrs)

      expect(record.errors.details).to eq(error_details)
    end

    it 'raises RecordInvalid from the bang methods' do
      klass.create!(attrs)

      expect { klass.create!(attrs) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when the unique index is found by the attribute' do
    let(:klass) { define_class(ActiveRecord::Base, :rls_entities) { validates_db_uniqueness_of :name } }
    let(:attrs) { { name: 'taken' } }
    let(:error_details) { { name: [{ error: :taken, value: 'taken' }] } }

    include_examples 'turns the collision into a validation error'
  end

  context 'when the unique index is found by the attribute and its scope' do
    let(:klass) { define_class(ActiveRecord::Base, :rls_scoped_entities) { validates_db_uniqueness_of :name, scope: :scope_key } }
    let(:attrs) { { name: 'taken', scope_key: 'one' } }
    let(:error_details) { { name: [{ error: :taken, value: 'taken' }] } }

    include_examples 'turns the collision into a validation error'
  end

  context 'when the unique index is named' do
    let(:klass) do
      define_class(ActiveRecord::Base, :rls_entities) do
        validates_db_uniqueness_of :name, index_name: :index_rls_entities_on_name
      end
    end
    let(:attrs) { { name: 'taken' } }
    let(:error_details) { { name: [{ error: :taken, value: 'taken' }] } }

    include_examples 'turns the collision into a validation error'
  end
end
