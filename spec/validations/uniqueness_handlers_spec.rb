RSpec.describe 'validates_db_uniqueness_of' do
  define_db = lambda do |opts|
    ActiveRecord::Base.establish_connection(opts)
    ActiveRecord::Schema.verbose = false

    class Entity < ActiveRecord::Base
      reset_column_information
    end
  end

  def define_table
    ActiveRecord::Schema.define(:version => 1) do
      drop_table :entities, if_exists: true
      create_table :entities do |t|
        yield(t)
      end
    end
  end

  def define_class(parent = Entity)
    Class.new(parent) do |klass|
      def klass.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end

      yield(klass) if block_given?
    end
  end

  shared_examples 'works as expected' do
    shared_examples 'ActiveRecord::Validation' do |skip_persisted = false|
      let(:persisted) { Entity.create(persisted_attrs) }

      before { persisted unless skip_persisted }

      describe 'valid?' do
        it 'returns false' do
          expect(db_uniqueness.new(persisted_attrs).valid?).to eq(false)
          expect(app_uniqueness.new(persisted_attrs).valid?).to eq(false)
        end

        it 'has exactly the same errors' do
          new = db_uniqueness.new(persisted_attrs).tap { |e| e.valid? }
          old = app_uniqueness.new(persisted_attrs).tap { |e| e.valid? }

          expect(old.errors.messages.sort).to eq(new.errors.messages.sort)
          expect(old.errors.details.sort).to eq(new.errors.details.sort)
        end

        context 'when wrapped by transaction' do
          it 'does not break transaction' do
            old = app_uniqueness.new(persisted_attrs)
            new = db_uniqueness.new(persisted_attrs)

            ActiveRecord::Base.connection.transaction do
              new.valid?
              old.valid?
            end

            expect(old.errors.messages.sort).to eq(new.errors.messages.sort)
            expect(old.errors.details.sort).to eq(new.errors.details.sort)
          end
        end
      end

      describe 'create/save/update' do
        it 'does not create' do
          expect { db_uniqueness.create(persisted_attrs) }.not_to change(Entity, :count)
          expect { app_uniqueness.create(persisted_attrs) }.not_to change(Entity, :count)
        end

        # Database raise only one unique constraint error per query
        # That means we can't catch all validations at once if there are more than one
        it 'has (almost) the same errors' do
          new = db_uniqueness.create(persisted_attrs)
          old = app_uniqueness.create(persisted_attrs)

          expect(new.errors.messages.size).to be > 0
          expect(new.errors.details.size).to be > 0

          expect(old.errors.messages).to include(new.errors.messages)
          expect(old.errors.details).to include(new.errors.details)
        end

        context 'when wrapped by transaction' do
          it 'does not break transaction' do
            new = db_uniqueness.new(persisted_attrs)
            old = app_uniqueness.new(persisted_attrs)

            ActiveRecord::Base.connection.transaction do
              new.save
              old.save
            end

            expect(new.errors.messages.size).to be > 0
            expect(new.errors.details.size).to be > 0

            expect(old.errors.messages).to include(new.errors.messages)
            expect(old.errors.details).to include(new.errors.details)
          end
        end
      end

      describe 'create!/save!/update!' do
        it 'does not create' do
          expect { db_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
          expect { app_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
        end

        def catch_error_message
          yield
        rescue ActiveRecord::RecordInvalid => e
          e.message.sub('Validation failed: ', '')
        end

        # Database raise only one unique constraint error per query
        # That means we can't catch all validations at once if there are more than one
        it 'raises validation error' do
          new = catch_error_message { db_uniqueness.create!(persisted_attrs) }
          old = catch_error_message { app_uniqueness.create!(persisted_attrs) }

          expect(new.size).to be > 0
          expect(old).to include(new)
        end

        context 'when wrapped by transaction' do
          it 'breaks transaction properly' do
            new = db_uniqueness.new(persisted_attrs)
            old = app_uniqueness.new(persisted_attrs)

            error_message = catch_error_message do
              ActiveRecord::Base.connection.transaction do
                new.save!
                old.save!
              end
            end

            expect(error_message.size).to be > 0
          end
        end
      end
    end

    context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is provided' do
      before do
        define_table do |t|
          t.string :field
        end
      end

      it 'does not raise an error' do
        ClimateControl.modify SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK: 'true' do
          expect do
            define_class { |klass| klass.validates_db_uniqueness_of :field }
          end.not_to raise_error
        end
      end
    end

    shared_examples 'when condition options return false' do
      describe '#valid?' do
        it 'skips querying the database' do
          StringIO.open do |io|
            klass.logger = Logger.new(io)
            expect { klass.new(field: 0).valid? }.not_to change(io, :string)
            klass.logger = nil
          end
        end
      end
    end

    shared_examples 'when condition options return true' do
      describe '#valid?' do
        it 'queries the database' do
          StringIO.open do |io|
            klass.logger = Logger.new(io)
            expect { klass.new(field: 0).valid? }.to change(io, :string)
            klass.logger = Logger.new(nil)
          end
        end
      end
    end

    context 'when condition options are passed' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      context 'when if option is passed' do
        context 'when if is a symbol' do
          context 'when method returns false' do
            let(:klass) do
              define_class do |klass|
                klass.validates_db_uniqueness_of :field, if: :skip
                klass.define_method(:skip) { false }
              end
            end

            include_examples 'when condition options return false'
          end

          context 'when method returns true' do
            let(:klass) do
              define_class do |klass|
                klass.validates_db_uniqueness_of :field, if: :skip
                klass.define_method(:skip) { true }
              end
            end

            include_examples 'when condition options return true'
          end
        end

        context 'when if is a proc' do
          context 'when proc has argument' do
            context 'when proc returns false' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, if: -> (entity) { entity.nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns true' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, if: -> (entity) { !entity.nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end

          context 'when proc has no argument' do
            context 'when proc returns false' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, if: -> { nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns true' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, if: -> { !nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end
        end
      end

      context 'when unless option is passed' do
        context 'when unless is a symbol' do
          context 'when method returns true' do
            let(:klass) do
              define_class do |klass|
                klass.validates_db_uniqueness_of :field, unless: :skip
                klass.define_method(:skip) { true }
              end
            end

            include_examples 'when condition options return false'
          end

          context 'when method returns false' do
            let(:klass) do
              define_class do |klass|
                klass.validates_db_uniqueness_of :field, unless: :skip
                klass.define_method(:skip) { false }
              end
            end

            include_examples 'when condition options return true'
          end
        end

        context 'when unless is a proc' do
          context 'when proc has argument' do
            context 'when proc returns true' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, unless: -> (entity) { !entity.nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns false' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, unless: -> (entity) { entity.nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end

          context 'when proc has no argument' do
            context 'when proc returns true' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, unless: -> { !nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns false' do
              let(:klass) do
                define_class do |klass|
                  klass.validates_db_uniqueness_of :field, unless: -> { nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end
        end
      end
    end

    context 'when has not proper validator' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:klass) { define_class }
      let(:attributes) { {field: 0} }

      it 'raises unique constrain error' do
        klass.create(attributes)
        expect { klass.create(attributes) }.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    context 'when has not supported option' do
      it 'raises error' do
        expect do
          define_class { |klass| klass.validates_db_uniqueness_of :field, unsupported_option: true }
        end.to raise_error DatabaseValidations::Errors::OptionIsNotSupported
      end
    end

    context 'when wrapped transaction is rolled back' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:app_uniqueness) { define_class(Entity) { |klass| klass.validates_uniqueness_of :field } }
      let(:db_uniqueness) { define_class(Entity) { |klass| klass.validates_db_uniqueness_of :field } }

      it 'does not create rows' do
        new = db_uniqueness.new(field: '0')
        old = app_uniqueness.new(field: '1')

        ActiveRecord::Base.connection.transaction do
          new.save
          old.save
          raise 'rollback'
        end rescue

        expect(Entity.count).to eq(0)
        expect(new.persisted?).to eq(false)
        expect(old.persisted?).to eq(false)
      end
    end

    context 'when parent class has validation' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:app_uniqueness) { define_class(define_class(Entity) { |klass| klass.validates_uniqueness_of :field }) }
      let(:db_uniqueness) { define_class(define_class(Entity) { |klass| klass.validates_db_uniqueness_of :field }) }

      let(:persisted_attrs) { {field: 'persisted'} }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when message is provided' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field, message: 'already exists' } }
      let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field, message: 'already exists' } }

      let(:persisted_attrs) { {field: 'persisted'} }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when parent class set validation of flow' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:parent_db_uniqueness) { define_class(Entity) }
      let(:parent_app_uniqueness) { define_class(Entity) }

      let(:db_uniqueness) { define_class(parent_db_uniqueness) }
      let(:app_uniqueness) { define_class(parent_app_uniqueness) }

      before do
        # Add validator to parent class
        parent_db_uniqueness.validates_db_uniqueness_of :field
        parent_app_uniqueness.validates_uniqueness_of :field
      end

      let(:persisted_attrs) { {field: 'persisted'} }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'without scope' do
      context 'without index' do
        before { define_table { |t| t.string :field } }

        it 'raises error on boot time' do
          expect do
            define_class { |klass| klass.validates_db_uniqueness_of :field }
          end.to raise_error DatabaseValidations::Errors::IndexNotFound,
                             'No unique index found with columns: ["field"]. '\
                             'Available indexes are: []. '\
                             'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
                             'For example, when you run migrations.'
        end
      end

      context 'with index' do
        before do
          define_table do |t|
            t.string :field
            t.index [:field], unique: true
          end
        end

        let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field } }
        let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field } }

        let(:persisted_attrs) { {field: 'persisted'} }

        it_behaves_like 'ActiveRecord::Validation'
      end
    end

    context 'with scope' do
      context 'without index' do
        before do
          define_table do |t|
            t.string :field_1
            t.string :field_2
          end
        end

        it 'raises error on boot time' do
          expect do
            define_class do |klass|
              klass.validates_db_uniqueness_of :field_1, scope: :field_2
            end
          end.to raise_error DatabaseValidations::Errors::IndexNotFound,
                             'No unique index found with columns: ["field_1", "field_2"]. '\
                             'Available indexes are: []. '\
                             'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
                             'For example, when you run migrations.'
        end
      end

      context 'with index' do
        before do
          define_table do |t|
            t.string :field_1
            t.string :field_2
            t.index [:field_2, :field_1], unique: true
          end
        end

        let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field_1, scope: :field_2 } }
        let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field_1, scope: :field_2 } }

        let(:persisted_attrs) { {field_1: 'persisted', field_2: 'persisted'} }

        it_behaves_like 'ActiveRecord::Validation'
      end
    end

    context 'with multiple attributes passed' do
      context 'without index' do
        before do
          define_table do |t|
            t.string :field_1
            t.string :field_2
            t.index [:field_1], unique: true
          end
        end

        it 'raises error with first attribute without index on boot time' do
          expect do
            define_class do |klass|
              klass.validates_db_uniqueness_of :field_1
              klass.validates_db_uniqueness_of :field_2
            end
          end.to raise_error DatabaseValidations::Errors::IndexNotFound,
                             'No unique index found with columns: ["field_2"]. '\
                             'Available indexes are: [columns: ["field_1"]]. '\
                             'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
                             'For example, when you run migrations.'
        end
      end

      context 'with indexes' do
        before do
          define_table do |t|
            t.string :field_1
            t.string :field_2
            t.index [:field_1], unique: true
            t.index [:field_2], unique: true
          end
        end

        let(:db_uniqueness) do
          define_class do |klass|
            klass.validates_db_uniqueness_of :field_1
            klass.validates_db_uniqueness_of :field_2
          end
        end

        let(:app_uniqueness) do
          define_class do |klass|
            klass.validates_uniqueness_of :field_1
            klass.validates_uniqueness_of :field_2
          end
        end

        let(:persisted_attrs) { {field_1: 'persisted', field_2: 'persisted_too'} }

        it_behaves_like 'ActiveRecord::Validation'
      end
    end
  end

  shared_examples 'supports condition option' do
    context 'when conditions option is provided' do
      before do
        define_table do |t|
          t.integer :field
          t.index [:field], unique: true, where: '(field > 1)'
        end
      end

      context 'when where clause is different' do
        it 'raises error' do
          expect do
            define_class { |klass| klass.validates_db_uniqueness_of :field, where: '(field < 1)' }
          end.to raise_error DatabaseValidations::Errors::IndexNotFound,
                             'No unique index found with columns: ["field"] and where: (field < 1). '\
                             'Available indexes are: [columns: ["field"] and where: (field > 1)]. '\
                             'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
                             'For example, when you run migrations.'
        end
      end

      context 'when where clause is the same' do
        let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field, where: '(field > 1)' } }
        let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field, conditions: -> { where('(field > 1)') } } }

        let(:persisted_attrs) { {field: 2} }

        it_behaves_like 'ActiveRecord::Validation'
      end
    end
  end

  shared_examples 'supports index_name option' do
    context 'when index_name option is passed' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true, name: :unique_index
        end
      end

      context 'when index_name is the same' do
        it 'works' do
          klass = define_class { |klass| klass.validates_db_uniqueness_of :field, index_name: :unique_index }
          klass.create!(field: 'field')
          expect { klass.create!(field: 'field') }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'when index_name is different' do
        it 'raises an error' do
          expect do
            define_class { |klass| klass.validates_db_uniqueness_of :field, index_name: :missing_index }
          end.to raise_error DatabaseValidations::Errors::IndexNotFound,
                             'No unique index found with name: "missing_index". '\
                             'Available indexes are: ["unique_index"]. '\
                             'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
                             'For example, when you run migrations.'
        end
      end
    end
  end

  shared_examples 'supports complex indexes' do
    context 'with index_name option' do
      before do
        define_table do |t|
          t.string :field
          t.index 'lower(field)', unique: true, name: :unique_index
        end
      end

      let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field, case_sensitive: false} }
      let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field, index_name: :unique_index, case_sensitive: false } }

      let(:persisted_attrs) { {field: 'field'} }

      before { db_uniqueness.create!(field: 'FIELD') }

      it 'works' do
        expect { db_uniqueness.create!(field: 'field') }.to raise_error ActiveRecord::RecordInvalid
      end

      it_behaves_like 'ActiveRecord::Validation', true
    end

    context 'without index_name option' do
      before do
        define_table do |t|
          t.string :field
          t.index 'lower(field)', unique: true
        end
      end

      it 'raises an error' do
        expect do
          define_class { |klass| klass.validates_db_uniqueness_of :field }
        end.to raise_error DatabaseValidations::Errors::IndexNotFound
      end
    end
  end

  describe 'postgresql' do
    before { define_db.call(adapter: 'postgresql', database: 'database_validations_test') }

    include_examples 'works as expected'
    include_examples 'supports condition option'
    include_examples 'supports index_name option'
    include_examples 'supports complex indexes'
  end

  describe 'sqlite3' do
    before { define_db.call(adapter: 'sqlite3', database: ':memory:') }

    include_examples 'works as expected'
  end

  describe 'mysql' do
    before { define_db.call(adapter: 'mysql2', database: 'database_validations_test', username: 'root') }

    include_examples 'works as expected'
    include_examples 'supports index_name option'
  end
end
