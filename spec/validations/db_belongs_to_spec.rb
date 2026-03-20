RSpec.describe 'db_belongs_to' do
  # rubocop:disable RSpec/LeakyConstantDeclaration
  # rubocop:disable Lint/ConstantDefinitionInBlock
  class Company < ActiveRecord::Base; end
  class BelongsUser < ActiveRecord::Base; end
  class DbBelongsUser < ActiveRecord::Base; end
  class Department < ActiveRecord::Base; end
  class MultiFkUser < ActiveRecord::Base; end
  # rubocop:enable RSpec/LeakyConstantDeclaration
  # rubocop:enable Lint/ConstantDefinitionInBlock

  let(:company_klass) { define_class(Company, :companies) }

  let(:belongs_to_user_klass) do
    define_class(BelongsUser, :belongs_users) do
      def name
        'BelongsToUserTemp'
      end

      belongs_to :company, optional: false
    end
  end

  let(:belongs_to_user_with_fk_klass) do
    define_class(DbBelongsUser, :db_belongs_users) do
      def name
        'BelongsToUserWithFKTemp'
      end

      belongs_to :company, optional: false
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
      context "when '#{method}' on '#{field}' with '#{company_id.inspect}'" do
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

      it 'respects validate: false' do
        expect { belongs_to_user_with_fk_klass.new(company_id: -1).save(validate: false) }
          .to raise_error(ActiveRecord::InvalidForeignKey)
        expect { db_belongs_to_user_klass.new(company_id: -1).save(validate: false) }
          .to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    describe 'save!' do
      include_examples 'pack', :save!

      it 'respects validate: false' do
        expect { belongs_to_user_with_fk_klass.new(company_id: -1).save!(validate: false) }
          .to raise_error(ActiveRecord::InvalidForeignKey)
        expect { db_belongs_to_user_klass.new(company_id: -1).save!(validate: false) }
          .to raise_error(ActiveRecord::InvalidForeignKey)
      end
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

    describe 'multiple db_belongs_to associations' do # rubocop:disable RSpec/MultipleMemoizedHelpers:
      let(:department_klass) { define_class(Department, :departments) }

      let(:multi_fk_klass) do
        define_class(MultiFkUser, :multi_fk_users) do
          db_belongs_to :company
          db_belongs_to :department
        end
      end

      before do
        ActiveRecord::Schema.define(version: 2) do
          create_table :departments
          create_table :multi_fk_users do |t|
            t.belongs_to :company, foreign_key: true
            t.belongs_to :department, foreign_key: true
          end
        end
      end

      it 'handles invalid company_id with valid department_id' do
        company_klass
        department = department_klass.create!
        record = multi_fk_klass.new(company_id: -1, department_id: department.id)
        expect(record.save).to be false
        expect(record.errors[:company]).to be_present
        expect(record.errors[:department]).to be_empty
      end

      it 'handles valid company_id with invalid department_id' do
        company = company_klass.create!
        department_klass
        record = multi_fk_klass.new(company_id: company.id, department_id: -1)
        expect(record.save).to be false
        expect(record.errors[:department]).to be_present
        expect(record.errors[:company]).to be_empty
      end

      it 'handles both invalid' do
        company_klass
        department_klass
        record = multi_fk_klass.new(company_id: -1, department_id: -1)
        expect(record.save).to be false
        expect(record.errors.messages.keys).to include(:company).or include(:department)
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

  describe 'sqlite3' do
    before do
      define_database(sqlite_configuration)
      define_tables
    end

    include_examples 'works as belongs_to'
  end

  describe 'mysql' do
    before do
      define_database(mysql_configuration)
      define_tables
    end

    include_examples 'works as belongs_to'
  end
end
