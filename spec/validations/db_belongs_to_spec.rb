RSpec.describe 'db_belongs_to' do
  class Company < ActiveRecord::Base; end # rubocop:disable RSpec/LeakyConstantDeclaration
  class BelongsUser < ActiveRecord::Base; end # rubocop:disable RSpec/LeakyConstantDeclaration
  class DbBelongsUser < ActiveRecord::Base; end # rubocop:disable RSpec/LeakyConstantDeclaration

  let(:company_klass) { define_class(Company, :companies) }

  let(:belongs_to_user_klass) do
    define_class(BelongsUser, :belongs_users) do
      def name
        'BelongsToUserTemp'
      end

      if RAILS_5
        belongs_to :company, optional: false
      else
        belongs_to :company, required: true
      end
    end
  end

  let(:db_belongs_to_user_klass) do
    define_class(DbBelongsUser, :db_belongs_users) do
      def name
        'DbBelongsToUserTemp'
      end

      db_belongs_to :company
    end
  end

  def define_tables
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

  shared_examples 'works as belongs_to' do
    shared_examples 'with company_id provided' do |method, field, company_id|
      context "#{method} on #{field} with #{company_id.inspect}" do
        specify do
          # Hack
          validate_db_queries = !(method == :valid? && [:existing_id, -1].include?(company_id))

          company_id = company_klass.create.id if company_id == :existing_id
          company_id = company_klass.create if company_id == :existing_company
          company_id = company_klass.new if company_id == :built

          old = belongs_to_user_klass.new(field => company_id)
          new = db_belongs_to_user_klass.new(field => company_id)

          new_err = nil

          old_err = rescue_error { old.send(method) }

          if validate_db_queries
            expect { new_err = rescue_error { new.send(method) } }.not_to make_database_queries(matching: 'SELECT')
          else
            new_err = rescue_error { new.send(method) }
          end

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

    describe 'check foreign key' do
      context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is provided' do
        before { allow(ENV).to receive(:[]).with('SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK').and_return('true') }

        it 'does not raise an error' do
          expect do
            Class.new(belongs_to_user_klass) { |klass| klass.db_belongs_to :company }
          end.not_to raise_error
        end
      end

      context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is missed' do
        it 'raise an error' do
          expect do
            Class.new(belongs_to_user_klass) { |klass| klass.db_belongs_to :company }
          end.to raise_error DatabaseValidations::Errors::ForeignKeyNotFound
        end
      end
    end
  end

  describe 'postgresql' do
    before do
      define_database(postgresql_configuration)
      define_tables
    end

    include_examples 'works as belongs_to'
  end

  # TODO: validate options
  # describe 'sqlite3' do
  #   before do
  #     define_database(sqlite_configuration)
  #     define_tables
  #   end
  #
  #   specify do
  #     expect { db_belongs_to_user_klass }.to raise_error DatabaseValidations::Errors::UnsupportedDatabase
  #   end
  # end

  describe 'mysql' do
    before do
      define_database(mysql_configuration)
      define_tables
    end

    include_examples 'works as belongs_to'
  end
end
