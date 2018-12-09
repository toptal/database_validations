RSpec.describe 'db_belongs_to' do
  class Company < ActiveRecord::Base; end
  class BelongsUser < ActiveRecord::Base; end
  class DbBelongsUser < ActiveRecord::Base; end

  def belongs_to_user_klass
    Class.new(BelongsUser) do |klass|
      def klass.name
        'BelongsToUserTemp'
      end

      klass.belongs_to :company, optional: false
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

  define_db = lambda do |opts|
    ActiveRecord::Base.establish_connection(opts)
    ActiveRecord::Schema.verbose = false

    ActiveRecord::Schema.define(:version => 1) do
      drop_table :belongs_users, if_exists: true, force: :cascade
      drop_table :db_belongs_users, if_exists: true, force: :cascade
      drop_table :companies, if_exists: true, force: :cascade

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

  describe 'postgresql' do
    before(:all) { define_db.call(adapter: 'postgresql', database: 'database_validations_test') }
    include_examples 'works as belongs_to'
  end

  describe 'sqlite3' do
    before(:all) { define_db.call(adapter: 'sqlite3', database: ':memory:') }

    specify do
      expect { db_belongs_to_user_klass }.to raise_error DatabaseValidations::Errors::UnsupportedDatabase
    end
  end

  describe 'mysql' do
    before(:all) { define_db.call(adapter: 'mysql2', database: 'database_validations_test') }
    include_examples 'works as belongs_to'
  end
end
