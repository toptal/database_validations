RSpec.describe 'Adapter.unique_error_columns' do
  def build_error(message)
    ActiveRecord::RecordNotUnique.new(message)
  end

  describe DatabaseValidations::Adapters::PostgresqlAdapter do
    it 'extracts the columns from the error detail' do
      error = build_error(
        'PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_entities_on_a_and_b" ' \
        'DETAIL:  Key (a, b)=(1, x) already exists.'
      )

      expect(described_class.unique_error_columns(error)).to eq(%w[a b])
    end

    it 'returns nil when the error has no detail' do
      error = build_error(
        'PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_entities_on_a_and_b"'
      )

      expect(described_class.unique_error_columns(error)).to be_nil
      expect(described_class.unique_index_name(error)).to eq('index_entities_on_a_and_b')
    end
  end
end
