require 'rubocop'
require 'rubocop/rspec/support'
require 'database_validations/rubocop/cops'

RSpec.shared_context 'with rubocop config', :rubocop_config do
  let(:config) { RuboCop::Config.new(described_class.cop_name => cop_config) }
end

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
