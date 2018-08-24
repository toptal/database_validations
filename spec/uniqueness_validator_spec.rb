require 'active_record'

RSpec.describe DatabaseValidations::UniquenessValidator do
  before do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.verbose = false

    class Entity < ActiveRecord::Base
      extend DatabaseValidations
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

  shared_examples 'ActiveRecord::Validation' do
    let(:persisted) { Entity.create(persisted_attrs) }

    before { persisted }

    describe 'create/save/update' do
      it 'does not create' do
        expect { db_uniqueness.create(persisted_attrs) }.not_to change(Entity, :count)
        expect { app_uniqueness.create(persisted_attrs) }.not_to change(Entity, :count)
      end

      it 'has the same errors' do
        new = db_uniqueness.create(persisted_attrs)
        old = app_uniqueness.create(persisted_attrs)

        expect(new.errors.messages).to eq(old.errors.messages)
        expect(new.errors.details).to eq(old.errors.details)
      end
    end

    describe 'create!/save!/update!' do
      it 'does not create' do
        expect { db_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
        expect { app_uniqueness.create!(persisted_attrs) rescue ActiveRecord::RecordInvalid }.not_to change(Entity, :count)
      end

      def catch_error
        yield
      rescue => e
        e
      end

      it 'raises validation error' do
        new = catch_error { db_uniqueness.create!(persisted_attrs) }
        old = catch_error { app_uniqueness.create!(persisted_attrs) }

        expect(new.message).to eq(old.message)
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
          t.index [:field_1, :field_2], unique: true
        end
      end

      let(:db_uniqueness) { define_class { |klass| klass.validates_db_uniqueness_of :field_1, scope: :field_2 } }
      let(:app_uniqueness) { define_class { |klass| klass.validates_uniqueness_of :field_1, scope: :field_2 } }

      let(:persisted_attrs) { {field_1: 'persisted', field_2: 'persisted'} }

      it_behaves_like 'ActiveRecord::Validation'
    end
  end
end
