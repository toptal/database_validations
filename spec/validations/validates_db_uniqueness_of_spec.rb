RSpec.describe '.validates_db_uniqueness_of' do
  let(:parent_class) { define_class }

  shared_examples 'works as expected' do
    shared_examples 'ActiveRecord::Validation' do |skip_persisted: false, query_count: 1|
      define_negated_matcher :not_change, :change
      define_negated_matcher :not_make_database_queries, :make_database_queries

      before { parent_class.create!(persisted_attrs) unless skip_persisted }

      describe 'valid?' do
        it 'makes a query for validation' do
          expect { db_uniqueness.new(persisted_attrs).valid? }
            .to make_database_queries(matching: /SELECT (?!sql)/, count: query_count)
          expect { app_uniqueness.new(persisted_attrs).valid? }
            .to make_database_queries(matching: /SELECT (?!sql)/, count: query_count)
        end

        it 'returns false' do
          expect(db_uniqueness.new(persisted_attrs).valid?).to eq(false)
          expect(app_uniqueness.new(persisted_attrs).valid?).to eq(false)
        end

        it 'has exactly the same errors' do
          new = db_uniqueness.new(persisted_attrs).tap(&:valid?)
          old = app_uniqueness.new(persisted_attrs).tap(&:valid?)

          expect(old.errors.messages.sort).to eq(new.errors.messages.sort)
          RAILS_5 && (expect(old.errors.details.sort).to eq(new.errors.details.sort))
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
            RAILS_5 && (expect(old.errors.details.sort).to eq(new.errors.details.sort))
          end
        end
      end

      describe 'create/save/update' do
        it 'does not make a query for validation' do
          expect { db_uniqueness.create(persisted_attrs) }
            .to not_make_database_queries(matching: /SELECT (?!sql)/)
            .and not_change(parent_class, :count)
          expect { app_uniqueness.create(persisted_attrs) }
            .to make_database_queries(matching: /SELECT (?!sql)/, count: query_count)
            .and not_change(parent_class, :count)
        end

        if RAILS_5
          it 'respects validate: false' do
            expect { db_uniqueness.new(persisted_attrs).save(validate: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
              .and not_change(parent_class, :count)
            expect { app_uniqueness.new(persisted_attrs).save(validate: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
              .and not_change(parent_class, :count)
          end
        end

        # Database raise only one unique constraint error per query
        # That means we can't catch all validations at once if there are more than one
        it 'has (almost) the same errors' do
          new = db_uniqueness.create(persisted_attrs)
          old = app_uniqueness.create(persisted_attrs)

          expect(new.errors.messages).to be_present
          RAILS_5 && (expect(new.errors.details).to be_present)

          expect(old.errors.messages.to_h).to include(new.errors.messages.to_h)
          RAILS_5 && (expect(old.errors.details.to_h).to include(new.errors.details.to_h))
        end

        context 'when wrapped by transaction' do
          it 'does not break transaction' do
            new = db_uniqueness.new(persisted_attrs)
            old = app_uniqueness.new(persisted_attrs)

            ActiveRecord::Base.connection.transaction do
              new.save
              old.save
            end

            expect(new.errors.messages).to be_present
            RAILS_5 && (expect(new.errors.details).to be_present)

            expect(old.errors.messages.to_h).to include(new.errors.messages.to_h)
            RAILS_5 && (expect(old.errors.details.to_h).to include(new.errors.details.to_h))
          end
        end
      end

      describe 'create!/save!/update!' do
        it 'does not make a query for validation' do
          expect { db_uniqueness.create!(persisted_attrs) }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_make_database_queries(matching: /SELECT (?!sql)/)
            .and not_change(parent_class, :count)

          expect { app_uniqueness.create!(persisted_attrs) }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and make_database_queries(matching: /SELECT (?!sql)/, count: query_count)
            .and not_change(parent_class, :count)
        end

        if RAILS_5
          it 'respects validate: false' do
            expect { db_uniqueness.new(persisted_attrs).save!(validate: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
              .and not_change(parent_class, :count)
            expect { app_uniqueness.new(persisted_attrs).save!(validate: false) }
              .to raise_error(ActiveRecord::RecordNotUnique)
              .and not_change(parent_class, :count)
          end
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

          expect(new).to be_present
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

            expect(error_message).to be_present
          end
        end
      end
    end

    context 'when SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK is provided' do
      before do
        define_table do |t|
          t.string :field
        end
        allow(ENV).to receive(:[]).with('SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK').and_return('true')
      end

      it 'does not raise an error' do
        expect do
          define_class { validates_db_uniqueness_of :field }
        end.not_to raise_error
      end
    end

    shared_examples 'when condition options return false' do
      describe '#valid?' do
        it 'skips querying the database' do
          StringIO.open do |io|
            klass.superclass.logger = Logger.new(io)
            expect { klass.new(field: 0).valid? }.not_to change(io, :string)
            klass.superclass.logger = nil
          end
        end
      end
    end

    shared_examples 'when condition options return true' do
      describe '#valid?' do
        it 'queries the database' do
          StringIO.open do |io|
            klass.superclass.logger = Logger.new(io)
            expect { klass.new(field: 0).valid? }.to change(io, :string)
            klass.superclass.logger = Logger.new(nil)
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
              define_class do
                validates_db_uniqueness_of :field, if: :skip
                define_method(:skip) { false }
              end
            end

            include_examples 'when condition options return false'
          end

          context 'when method returns true' do
            let(:klass) do
              define_class do
                validates_db_uniqueness_of :field, if: :skip
                define_method(:skip) { true }
              end
            end

            include_examples 'when condition options return true'
          end
        end

        context 'when if is a proc' do
          context 'when proc has argument' do
            context 'when proc returns false' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, if: ->(entity) { entity.nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns true' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, if: ->(entity) { !entity.nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end

          context 'when proc has no argument' do
            context 'when proc returns false' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, if: -> { nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns true' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, if: -> { !nil? }
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
              define_class do
                validates_db_uniqueness_of :field, unless: :skip
                define_method(:skip) { true }
              end
            end

            include_examples 'when condition options return false'
          end

          context 'when method returns false' do
            let(:klass) do
              define_class do
                validates_db_uniqueness_of :field, unless: :skip
                define_method(:skip) { false }
              end
            end

            include_examples 'when condition options return true'
          end
        end

        context 'when unless is a proc' do
          context 'when proc has argument' do
            context 'when proc returns true' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, unless: ->(entity) { !entity.nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns false' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, unless: ->(entity) { entity.nil? }
                end
              end

              include_examples 'when condition options return true'
            end
          end

          context 'when proc has no argument' do
            context 'when proc returns true' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, unless: -> { !nil? }
                end
              end

              include_examples 'when condition options return false'
            end

            context 'when proc returns false' do
              let(:klass) do
                define_class do
                  validates_db_uniqueness_of :field, unless: -> { nil? }
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
      let(:attributes) { { field: 0 } }

      it 'raises unique constrain error' do
        klass.create(attributes)
        expect { klass.create(attributes) }.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    context 'when wrapped transaction is rolled back' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:app_uniqueness) { define_class(parent_class) { validates_uniqueness_of :field } }
      let(:db_uniqueness) { define_class(parent_class) { validates_db_uniqueness_of :field } }

      it 'does not create rows' do
        new = db_uniqueness.new(field: '0')
        old = app_uniqueness.new(field: '1')

        begin
          ActiveRecord::Base.connection.transaction do
            new.save
            old.save
            raise 'rollback'
          end
        rescue StandardError
          nil
        end
        expect(parent_class.count).to eq(0)
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

      let(:app_uniqueness) { define_class(define_class(parent_class) { validates_uniqueness_of :field }) }
      let(:db_uniqueness) { define_class(define_class(parent_class) { validates_db_uniqueness_of :field }) }

      let(:persisted_attrs) { { field: 'persisted' } }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when in rescue always' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end

        parent_class.create!(persisted_attrs)
      end

      let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field, rescue: :always } }
      let(:app_uniqueness) { define_class { validates_uniqueness_of :field } }

      let(:persisted_attrs) { { field: 'persisted' } }

      it 'rescues the error' do
        expect { db_uniqueness.new(persisted_attrs).save!(validate: false) }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect { app_uniqueness.new(persisted_attrs).save!(validate: false) }
          .to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'when in enhanced mode' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field } }
      let(:app_uniqueness) { define_class { validates_db_uniqueness_of :field, mode: :enhanced } }

      let(:persisted_attrs) { { field: 'persisted' } }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when in standard mode' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field } }
      let(:app_uniqueness) { define_class { validates_db_uniqueness_of :field, mode: :standard } }

      let(:persisted_attrs) { { field: 'persisted' } }

      it_behaves_like 'ActiveRecord::Validation'

      context do
        define_negated_matcher :not_change, :change

        before { parent_class.create!(persisted_attrs) }

        it "doesn't rescue from the constraint violation" do
          expect_any_instance_of(ActiveRecord::Validations::UniquenessValidator)
            .to receive(:scope_relation).twice.and_return(RAILS_5 ? app_uniqueness.none : '1=0')

          expect { app_uniqueness.create(persisted_attrs) }
            .to raise_error(ActiveRecord::RecordNotUnique)
            .and not_change(parent_class, :count)

          expect { app_uniqueness.create!(persisted_attrs) }
            .to raise_error(ActiveRecord::RecordNotUnique)
            .and not_change(parent_class, :count)
        end
      end
    end

    context 'when message is provided' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end
      end

      let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field, message: 'already exists' } }
      let(:app_uniqueness) { define_class { validates_uniqueness_of :field, message: 'already exists' } }

      let(:persisted_attrs) { { field: 'persisted' } }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when parent class set validation of flow' do
      before do
        define_table do |t|
          t.string :field
          t.index [:field], unique: true
        end

        # Add validator to parent class
        parent_db_uniqueness.validates_db_uniqueness_of :field
        parent_app_uniqueness.validates_uniqueness_of :field
      end

      let(:parent_db_uniqueness) { define_class(parent_class) }
      let(:parent_app_uniqueness) { define_class(parent_class) }

      let(:db_uniqueness) { define_class(parent_db_uniqueness) }
      let(:app_uniqueness) { define_class(parent_app_uniqueness) }

      let(:persisted_attrs) { { field: 'persisted' } }

      it_behaves_like 'ActiveRecord::Validation'
    end

    context 'when klass is abstract' do
      let(:db_uniqueness) {}

      it 'does not check the index presence' do
        expect do
          define_class do
            self.abstract_class = true
            validates_db_uniqueness_of :field
          end
        end.not_to raise_error
      end
    end

    context 'without scope' do
      context 'without index' do
        before { define_table { |t| t.string :field } }

        it 'raises error on boot time' do
          expect do
            define_class { validates_db_uniqueness_of :field }
          end.to raise_index_not_found(
            'No unique index found with columns: ["field"] in table "entities". '\
            'Available indexes are: [].'
          )
        end
      end

      context 'with index' do
        before do
          define_table do |t|
            t.string :field
            t.index [:field], unique: true
          end
        end

        let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field } }
        let(:app_uniqueness) { define_class { validates_uniqueness_of :field } }

        let(:persisted_attrs) { { field: 'persisted' } }

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
            define_class do
              validates_db_uniqueness_of :field_1, scope: :field_2
            end
          end.to raise_index_not_found(
            'No unique index found with columns: ["field_1", "field_2"] in table "entities". '\
            'Available indexes are: [].'
          )
        end
      end

      context 'with index' do
        before do
          define_table do |t|
            t.string :field_1
            t.string :field_2
            t.index %i[field_2 field_1], unique: true
          end
        end

        let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field_1, scope: :field_2 } }
        let(:app_uniqueness) { define_class { validates_uniqueness_of :field_1, scope: :field_2 } }

        let(:persisted_attrs) { { field_1: 'persisted', field_2: 'persisted' } }

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
            define_class do
              validates_db_uniqueness_of :field_1
              validates_db_uniqueness_of :field_2
            end
          end.to raise_index_not_found(
            'No unique index found with columns: ["field_2"] in table "entities". '\
            'Available indexes are: [columns: ["field_1"]].'
          )
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
          define_class do
            validates_db_uniqueness_of :field_1
            validates_db_uniqueness_of :field_2
          end
        end

        let(:app_uniqueness) do
          define_class do
            validates_uniqueness_of :field_1
            validates_uniqueness_of :field_2
          end
        end

        let(:persisted_attrs) { { field_1: 'persisted', field_2: 'persisted_too' } }

        it_behaves_like 'ActiveRecord::Validation', query_count: 2
      end
    end

    context 'when defined through validates' do
      before do
        define_table do |t|
          t.string :field_1
          t.string :field_2
          t.index [:field_1], unique: true
          t.index [:field_2], unique: true
        end
      end

      let(:db_uniqueness) { define_class(parent_class) { validates :field_1, :field_2, db_uniqueness: true } }
      let(:app_uniqueness) { define_class(parent_class) { validates :field_1, :field_2, uniqueness: true } }

      let(:persisted_attrs) { { field_1: 'persisted', field_2: 'persisted_too' } }

      it_behaves_like 'ActiveRecord::Validation', query_count: 2
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
            define_class { validates_db_uniqueness_of :field, where: '(field < 1)' }
          end.to raise_index_not_found(
            'No unique index found with columns: ["field"] and where: (field < 1) in table "entities". '\
            'Available indexes are: [columns: ["field"] and where: (field > 1)].'
          )
        end
      end

      context 'when where clause is the same' do
        let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field, where: '(field > 1)' } }
        let(:app_uniqueness) { define_class { validates_uniqueness_of :field, conditions: -> { where('(field > 1)') } } }

        context 'when condition should be considered' do
          let(:persisted_attrs) { { field: 2 } }

          it_behaves_like 'ActiveRecord::Validation'
        end

        context 'when condition should be ignored' do
          let(:persisted_attrs) { { field: 0 } }

          describe '#valid?' do
            it 'works' do
              expect(db_uniqueness.new(persisted_attrs).valid?).to eq(true)
              expect(app_uniqueness.new(persisted_attrs).valid?).to eq(true)
            end
          end

          describe '#create/save/update' do
            it 'works' do
              expect(db_uniqueness.create(persisted_attrs)).to be_persisted
              expect(app_uniqueness.create(persisted_attrs)).to be_persisted
            end
          end

          describe '#create!/save!/update!' do
            it 'works' do
              expect { db_uniqueness.create!(persisted_attrs) }.not_to raise_error
              expect { app_uniqueness.create!(persisted_attrs) }.not_to raise_error
            end
          end
        end
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
          klass = define_class { validates_db_uniqueness_of :field, index_name: :unique_index }
          klass.create!(field: 'field')
          expect { klass.create!(field: 'field') }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'when index_name is different' do
        it 'raises an error' do
          expect do
            define_class { validates_db_uniqueness_of :field, index_name: :missing_index }
          end.to raise_index_not_found(
            'No unique index found with name: "missing_index" in table "entities". '\
            'Available indexes are: ["unique_index"].'
          )
        end
      end
    end
  end

  shared_examples 'supports index_name with where option' do
    context 'when index has where option' do
      before do
        define_table do |t|
          t.string :field
          t.string :another
          t.index [:field], unique: true, name: :unique_index, where: '(another IS NOT NULL)'
        end
      end

      context 'when where option is skipped' do
        it 'raises an error due valid? is inconsistent with the index' do
          expect do
            define_class { validates_db_uniqueness_of :field }
          end.to raise_index_not_found(
            'No unique index found with columns: ["field"] in table "entities". '\
            'Available indexes are: [columns: ["field"] and where: (another IS NOT NULL)].'
          )
        end
      end

      context 'when where option is provided' do
        it 'does not raise an error' do
          expect do
            define_class { validates_db_uniqueness_of :field, where: '(another IS NOT NULL)' }
          end.not_to raise_error
        end
      end
    end
  end

  shared_examples 'supports index_name with scope option' do
    context 'when index uses many columns' do
      before do
        define_table do |t|
          t.string :field
          t.string :another
          t.index %i[field another], unique: true, name: :unique_index
        end
      end

      context 'when scope option is skipped' do
        it 'raises an error due valid? is inconsistent with the index' do
          expect do
            define_class { validates_db_uniqueness_of :field }
          end.to raise_index_not_found(
            'No unique index found with columns: ["field"] in table "entities". '\
            'Available indexes are: [columns: ["field", "another"]].'
          )
        end
      end

      context 'when scope option is provided' do
        it 'does not raise an error' do
          expect do
            define_class { validates_db_uniqueness_of :field, scope: :another }
          end.not_to raise_error
        end
      end
    end
  end

  shared_examples 'supports complex indexes' do
    next unless RAILS_5

    context 'with index_name option' do
      let(:app_uniqueness) { define_class { validates_uniqueness_of :field, case_sensitive: false } }
      let(:db_uniqueness) { define_class { validates_db_uniqueness_of :field, index_name: :unique_index, case_sensitive: false } }

      let(:persisted_attrs) { { field: 'field' } }

      before do
        define_table do |t|
          t.string :field
          t.index 'lower(field)', unique: true, name: :unique_index
        end

        db_uniqueness.create!(field: 'FIELD')
      end

      it 'works' do
        expect { db_uniqueness.create!(field: 'field') }.to raise_error ActiveRecord::RecordInvalid
      end

      it_behaves_like 'ActiveRecord::Validation', skip_persisted: true
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
          define_class { validates_db_uniqueness_of :field }
        end.to raise_index_not_found
      end
    end
  end

  shared_examples 'when index_name is passed only one attribute can be provided' do
    it 'throws an error' do
      expect do
        define_class { validates_db_uniqueness_of :field, :another, index_name: :unique_index }
      end.to raise_error ArgumentError, /When index_name is provided validator can have only one attribute./
    end
  end

  describe 'postgresql' do
    before { define_database(postgresql_configuration) }

    include_examples 'works as expected'
    include_examples 'supports condition option'
    include_examples 'supports index_name option'
    include_examples 'supports complex indexes'
    include_examples 'supports index_name with where option'
    include_examples 'supports index_name with scope option'
    include_examples 'when index_name is passed only one attribute can be provided'
  end

  describe 'postgresql_postgis' do
    before { define_database(postgresql_postgis_configuration) }

    include_examples 'works as expected'
    include_examples 'supports condition option'
    include_examples 'supports index_name option'
    include_examples 'supports complex indexes'
    include_examples 'supports index_name with where option'
    include_examples 'supports index_name with scope option'
    include_examples 'when index_name is passed only one attribute can be provided'
  end

  describe 'sqlite3' do
    before { define_database(sqlite_configuration) }

    include_examples 'works as expected'
    include_examples 'when index_name is passed only one attribute can be provided'
  end

  describe 'mysql' do
    before { define_database(mysql_configuration) }

    include_examples 'works as expected'
    include_examples 'supports index_name option'
    include_examples 'supports index_name with scope option'
    include_examples 'when index_name is passed only one attribute can be provided'
  end
end
