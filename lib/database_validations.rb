require 'active_record'

require 'database_validations/version'
require 'database_validations/railtie' if defined?(Rails)
require 'database_validations/uniqueness_validator'
require 'database_validations/uniqueness_options'
require 'database_validations/uniqueness_options_storage'
require 'database_validations/errors'
require 'database_validations/helpers'
require 'database_validations/adapters'

module DatabaseValidations
  extend ActiveSupport::Concern
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.include(DatabaseValidations)
end
