require 'active_record'

require 'database_validations/version'

require 'database_validations/rails/railtie' if defined?(Rails)

require 'database_validations/lib/validates_db_uniqueness_of/db_uniqueness_validator'
require 'database_validations/lib/validates_db_uniqueness_of/uniqueness_handlers'
require 'database_validations/lib/validates_db_uniqueness_of/uniqueness_options'

require 'database_validations/lib/db_belongs_to/db_presence_validator'
require 'database_validations/lib/db_belongs_to/belongs_to_handlers'
require 'database_validations/lib/db_belongs_to/belongs_to_options'

require 'database_validations/lib/rescuer'
require 'database_validations/lib/options_storage'
require 'database_validations/lib/errors'
require 'database_validations/lib/helpers'
require 'database_validations/lib/adapters'

module DatabaseValidations
  extend ActiveSupport::Concern
end

ActiveRecord::Base.include(DatabaseValidations) if defined?(ActiveRecord::Base)
