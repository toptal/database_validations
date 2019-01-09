require 'rubocop/spec_helper'

RSpec.describe RuboCop::Cop::DatabaseValidations::BelongsTo do # rubocop:disable RSpec/FilePath
  subject(:cop) { described_class.new }

  it 'detects `belongs_to`: true``' do
    expect_offense(<<-RUBY)
      belongs_to :company
      ^^^^^^^^^^ Use `db_belongs_to`.
    RUBY
  end

  it 'detects `belongs_to` with an option' do
    expect_offense(<<-RUBY)
      belongs_to :company, touch: true
      ^^^^^^^^^^ Use `db_belongs_to`.
    RUBY
  end

  it 'ignores `belongs_to` with optional' do
    expect_no_offenses(<<-RUBY)
      belongs_to :company, optional: true
    RUBY
  end

  it 'ignores `belongs_to` with required' do
    expect_no_offenses(<<-RUBY)
      belongs_to :company, required: true
    RUBY
  end

  it 'ignores `belongs_to` with polymorphic' do
    expect_no_offenses(<<-RUBY)
      belongs_to :company, polymorphic: true
    RUBY
  end

  it 'ignores `belongs_to` with foreign_type' do
    expect_no_offenses(<<-RUBY)
      belongs_to :role, foreign_type: User
    RUBY
  end
end
