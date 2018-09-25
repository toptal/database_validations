require 'active_record'

require 'database_validations/version'

require 'database_validations/rails/railtie' if defined?(Rails)

require 'database_validations/validations/uniqueness_validator'
require 'database_validations/validations/uniqueness_options'
require 'database_validations/validations/uniqueness_options_storage'
require 'database_validations/validations/errors'
require 'database_validations/validations/helpers'
require 'database_validations/validations/adapters'

module DatabaseValidations
  extend ActiveSupport::Concern
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.include(DatabaseValidations)
end
