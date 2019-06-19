RSpec.describe '.validates_db_presence_of' do
  before do
    define_database(postgresql_configuration)

    define_table do |t|
      t.string :field
    end
  end

  context 'when cover simple field' do
    let(:simple_klass) { define_class { validates :field, presence: true } }
    let(:db_klass) { define_class { validates :field, db_presence: true } }

    %w[save save! valid?].each do |method|
      context "with #{method}" do
        it 'works for fields' do
          simple = simple_klass.new
          db = db_klass.new

          simple_result = rescue_error { simple.public_send(method) }
          db_result = rescue_error { db.public_send(method) }

          expect(db.errors.messages).to eq(simple.errors.messages)
          expect(db_result).to eq(simple_result)
          expect(db.persisted?).to eq(simple.persisted?)
        end
      end
    end
  end
end
