require 'database_validations/rspec/matchers'

RSpec.describe 'validate_db_uniqueness_of' do
  before do
    define_database(sqlite_configuration)

    define_table(:entities) do |t|
      t.string :field
    end

    allow(ENV).to receive(:[]).with('SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK').and_return('true')
  end

  context 'when only field is provided' do
    subject { define_class { validates_db_uniqueness_of :field } }

    it { is_expected.to validate_db_uniqueness_of :field }
    it { is_expected.not_to validate_db_uniqueness_of :wrong }
  end

  context 'when message option is specified' do
    subject { define_class { validates_db_uniqueness_of :field, message: 'duplicated' } }

    it { is_expected.to validate_db_uniqueness_of(:field).with_message('duplicated') }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_message('wrong') }
  end

  context 'when scope option is specified' do
    subject { define_class { validates_db_uniqueness_of :field, scope: :another } }

    it { is_expected.to validate_db_uniqueness_of(:field).scoped_to(:another) }
    it { is_expected.not_to validate_db_uniqueness_of(:field).scoped_to(:wrong) }
  end

  context 'when where option is specified' do
    subject { define_class { validates_db_uniqueness_of :field, where: 'another IS NULL' } }

    before do
      allow_any_instance_of(DatabaseValidations::Adapters::BaseAdapter) # rubocop:disable RSpec/AnyInstance
        .to receive(:support_option?).and_return(true)
    end

    it { is_expected.to validate_db_uniqueness_of(:field).with_where('another IS NULL') }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_where('another IS NOT NULL') }
  end

  context 'when index_name option is specified' do
    subject { define_class { validates_db_uniqueness_of :field, index_name: :unique_index } }

    before do
      allow_any_instance_of(DatabaseValidations::Adapters::BaseAdapter) # rubocop:disable RSpec/AnyInstance
        .to receive(:support_option?).and_return(true)
    end

    it { is_expected.to validate_db_uniqueness_of(:field).with_index(:unique_index) }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_index(:another_index) }
  end

  context 'when case_sensitive option is specified' do
    subject { define_class { validates_db_uniqueness_of :field, case_sensitive: false } }

    before do
      allow_any_instance_of(DatabaseValidations::Adapters::BaseAdapter) # rubocop:disable RSpec/AnyInstance
        .to receive(:support_option?).and_return(true)
    end

    it { is_expected.to validate_db_uniqueness_of(:field).case_insensitive }
  end

  context 'when instance of model is provided' do
    subject { define_class { validates_db_uniqueness_of :field }.new }

    it { is_expected.to validate_db_uniqueness_of(:field) }
    it { is_expected.not_to validate_db_uniqueness_of(:another_field) }
  end
end
