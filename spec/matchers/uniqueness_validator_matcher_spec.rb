require 'database_validations/rspec/matchers'

RSpec.describe 'validate_db_uniqueness_of' do

  def define_class(parent = ActiveRecord::Base)
    Class.new(parent) do |klass|
      def klass.model_name
        ActiveModel::Name.new(self, nil, 'temp')
      end

      yield(klass) if block_given?
    end
  end

  around do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.verbose = false

    ClimateControl.modify SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK: 'true' do
      example.run
    end
  end

  context 'when only field is provided' do
    subject { define_class { |klass| klass.validates_db_uniqueness_of :field } }

    it { is_expected.to validate_db_uniqueness_of :field }
    it { is_expected.not_to validate_db_uniqueness_of :wrong }
  end

  context 'when message option is specified' do
    subject { define_class { |klass| klass.validates_db_uniqueness_of :field, message: 'duplicated' }}

    it { is_expected.to validate_db_uniqueness_of(:field).with_message('duplicated') }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_message('wrong') }
  end

  context 'when scope option is specified' do
    subject { define_class { |klass| klass.validates_db_uniqueness_of :field, scope: :another } }

    it { is_expected.to validate_db_uniqueness_of(:field).scoped_to(:another) }
    it { is_expected.not_to validate_db_uniqueness_of(:field).scoped_to(:wrong) }
  end

  context 'when where option is specified' do
    before { allow_any_instance_of(DatabaseValidations::Adapters::BaseAdapter).to receive(:support_option?).and_return(true) }

    subject { define_class { |klass| klass.validates_db_uniqueness_of :field, where: 'another IS NULL' } }

    it { is_expected.to validate_db_uniqueness_of(:field).with_where('another IS NULL') }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_where('another IS NOT NULL') }
  end

  context 'when index_name option is specified' do
    before { allow_any_instance_of(DatabaseValidations::Adapters::BaseAdapter).to receive(:support_option?).and_return(true) }

    subject { define_class { |klass| klass.validates_db_uniqueness_of :field, index_name: :unique_index } }

    it { is_expected.to validate_db_uniqueness_of(:field).with_index(:unique_index) }
    it { is_expected.not_to validate_db_uniqueness_of(:field).with_index(:another_index) }
  end
end
