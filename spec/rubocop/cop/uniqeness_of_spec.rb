require 'rubocop/spec_helper'

RSpec.describe RuboCop::Cop::DatabaseValidations::UniquenessOf do # rubocop:disable RSpec/FilePath
  subject(:cop) { described_class.new }

  it 'detects `uniqueness: true`' do
    expect_offense(<<-RUBY)
      validates :slug, uniqueness: true
                       ^^^^^^^^^^^^^^^^ Use `validates_db_uniqueness_of`.
    RUBY
  end

  it 'detects `uniqueness` on multiple fields' do
    expect_offense(<<-RUBY)
      validates :code, :name, uniqueness: true
                              ^^^^^^^^^^^^^^^^ Use `validates_db_uniqueness_of`.
    RUBY
  end

  it 'detects conditional uniqeuness valudation' do
    expect_offense(<<-RUBY)
      validates :main, uniqueness: {scope: :client_id}, if: -> { main? && main_changed? }
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `validates_db_uniqueness_of`.
    RUBY
  end
end
