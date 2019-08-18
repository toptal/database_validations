RSpec::Matchers.define :raise_index_not_found do |message = nil|
  match do |actual|
    expect { actual.call }.to raise_error(DatabaseValidations::Errors::IndexNotFound, message_matcher(message))
  end

  def message_matcher(message)
    text = ' '\
          'Use ENV[\'SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK\']=true in case you want to skip the check. '\
          'For example, when you run migrations.'.freeze

    if message
      start_with(message)
        .and end_with(text)
    else
      end_with(text)
    end
  end

  supports_block_expectations
end
