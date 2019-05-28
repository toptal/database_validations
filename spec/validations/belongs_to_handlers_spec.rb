RSpec.describe 'db_belongs_to' do
  class Company < ActiveRecord::Base; end
  class BelongsUser < ActiveRecord::Base; end
  class DbBelongsUser < ActiveRecord::Base; end

  def belongs_to_user_klass
    Class.new(BelongsUser) do |klass|
      def klass.name
        'BelongsToUserTemp'
      end

      if RAILS_5
        klass.belongs_to :company, optional: false
      else
        klass.belongs_to :company, required: true
      end
    end
  end

  def db_belongs_to_user_klass
    Class.new(DbBelongsUser) do |klass|
      def klass.name
        'DbBelongsToUserTemp'
      end

      klass.db_belongs_to :company
    end
  end

  def define_db(connection_options)
    ActiveRecord::Base.establish_connection(connection_options)
    ActiveRecord::Schema.verbose = false

    clear_database!(connection_options)

    ActiveRecord::Schema.define(version: 1) do
      create_table :companies

      create_table :belongs_users do |t|
        t.belongs_to :company
      end

      create_table :db_belongs_users do |t|
        t.belongs_to :company, foreign_key: true
      end
    end
  end

  def rescue_error
    yield
    :no_error
  rescue ActiveRecord::RecordInvalid => e
    e.message
  end

  shared_examples 'works as belongs_to' do
    shared_examples 'check foreign key' do
      context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is provided' do
        before do
          allow(ENV)
            .to receive(:[])
            .with('SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK')
            .and_return('true')
        end

        it 'does not raise an error' do
          expect do
            Class.new(BelongsUser) { |klass| klass.db_belongs_to :company }
          end.not_to raise_error
        end
      end

      context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is missed' do
        it 'raise an error' do
          expect do
            Class.new(BelongsUser) { |klass| klass.db_belongs_to :company }
          end.to raise_error DatabaseValidations::Errors::ForeignKeyNotFound
        end
      end
    end

    shared_examples 'with company_id provided' do |method, field, company_id|
      context "#{method} on #{field} with #{company_id.inspect}" do
        specify do
          # Hack
          company_id = Company.create.id if company_id == :existing_id
          company_id = Company.create if company_id == :existing_company
          company_id = Company.new if company_id == :built

          old = belongs_to_user_klass.new(field => company_id)
          new = db_belongs_to_user_klass.new(field => company_id)

          old_err = rescue_error { old.send(method) }
          new_err = rescue_error { new.send(method) }

          expect(new_err).to eq(old_err)
          expect(new.errors.messages).to eq(old.errors.messages)
          expect(new.persisted?).to eq(old.persisted?)
        end
      end
    end

    shared_examples 'pack' do |method|
      include_examples 'with company_id provided', method, :company_id, :existing_id
      include_examples 'with company_id provided', method, :company, :existing_company
      include_examples 'with company_id provided', method, :company_id, -1
      include_examples 'with company_id provided', method, :company_id, nil
      include_examples 'with company_id provided', method, :company, :built
      include_examples 'with company_id provided', method, :company, nil
    end

    describe 'valid?' do
      include_examples 'pack', :valid?
    end

    describe 'save' do
      include_examples 'pack', :save
    end

    describe 'save!' do
      include_examples 'pack', :save!
    end

    include_examples 'check foreign key'
  end

  # rubocop:disable RSpec/BeforeAfterAll
  describe 'postgresql' do
    before(:context) { define_db(postgresql_configuration) }

    include_examples 'works as belongs_to'
  end

  describe 'sqlite3' do
    before(:context) { define_db(sqlite_configuration) }

    specify do
      expect { db_belongs_to_user_klass }.to raise_error DatabaseValidations::Errors::UnsupportedDatabase
    end
  end

  describe 'mysql' do
    before(:context) { define_db(mysql_configuration) }

    include_examples 'works as belongs_to'
  end
  # rubocop:enable RSpec/BeforeAfterAll
end
