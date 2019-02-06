require 'active_record'

require 'database_validations/version'

require 'database_validations/rails/railtie' if defined?(Rails)

require 'database_validations/validations/uniqueness_handlers'
require 'database_validations/validations/uniqueness_options'

require 'database_validations/validations/belongs_to_presence_validator'
require 'database_validations/validations/belongs_to_handlers'
require 'database_validations/validations/belongs_to_options'

require 'database_validations/validations/valid_without_database_validations'
require 'database_validations/validations/options_storage'
require 'database_validations/validations/errors'
require 'database_validations/validations/helpers'
require 'database_validations/validations/adapters'

module DatabaseValidations
  extend ActiveSupport::Concern
end

ActiveRecord::Base.include(DatabaseValidations) if defined?(ActiveRecord::Base)
