RSpec.describe DatabaseValidations::UniquenessValidator do
  define_db = lambda do |opts|
    ActiveRecord::Base.establish_connection(opts)
    ActiveRecord::Schema.verbose = false

    class Entity < ActiveRecord::Base
      reset_column_information
    end
  end

  def define_table
    ActiveRecord::Schema.define(:version => 1) do
      create_table :entities do |t|
        yield(t)
      end
    end
  end

  def define_class
    Class.new(Entity) do |klass|
      def klass.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end

      yield(klass)
    end
  end

  shared_examples 'works as expected' do
    shared_examples 'ActiveRecord::Validation' do
      let(:persisted) { Entity.create(persisted_attrs) }

      before { persisted }

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

          expect(old.errors.messages).to include(new.errors.messages)
          expect(old.errors.details).to include(new.errors.details)
        end
      end

      describe 'create!/save!/update!' do
        it 'does not create' do
          expect { db_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
          expect { app_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
        end

        def catch_error_message
          yield
        rescue => e
          e.message.tr('Validation failed: ', '')
        end

        # Database raise only one unique constraint error per query
        # That means we can't catch all validations at once if there are more than one
        it 'raises validation error' do
          new = catch_error_message { db_uniqueness.create!(persisted_attrs) }
          old = catch_error_message { app_uniqueness.create!(persisted_attrs) }

          expect(old).to include(new)
        end
      end
    end

    context 'without scope' do
      context 'without index' do
        before { define_table { |t| t.string :field } }

        it 'raises error on boot time' do
          expect do
            define_class { |klass| klass.validates_db_uniqueness_of :field }
          end.to raise_error DatabaseValidations::Errors::IndexNotFound, 'No unique index found with columns: ["field"]'
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
          end.to raise_error DatabaseValidations::Errors::IndexNotFound, 'No unique index found with columns: ["field_1", "field_2"]'
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
          end.to raise_error DatabaseValidations::Errors::IndexNotFound, 'No unique index found with columns: ["field_2"]'
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

  describe 'postgresql' do
    before { define_db.call(adapter: 'postgresql', database: 'database_validations_test') }

    after { ActiveRecord::Base.connection.drop_table(Entity.table_name, if_exists: true) }

    include_examples 'works as expected'
  end

  describe 'sqlite3' do
    before { define_db.call(adapter: 'sqlite3', database: ':memory:') }

    include_examples 'works as expected'
  end

  describe 'mysql' do
    before { define_db.call(adapter: 'mysql2', database: 'database_validations_test', username: 'root') }

    after { ActiveRecord::Base.connection.drop_table(Entity.table_name, if_exists: true) }

    include_examples 'works as expected'
  end
end
