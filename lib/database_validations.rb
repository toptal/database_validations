require 'active_record'

require 'database_validations/version'

require 'database_validations/rails/railtie' if defined?(Rails)

require 'database_validations/lib/checkers/db_uniqueness_validator'
require 'database_validations/lib/checkers/db_presence_validator'

require 'database_validations/lib/validators/db_uniqueness_validator'
require 'database_validations/lib/validators/db_presence_validator'

require 'database_validations/lib/storage'
require 'database_validations/lib/attribute_validator'
require 'database_validations/lib/key_generator'
require 'database_validations/lib/uniqueness_key_extractor'
require 'database_validations/lib/presence_key_extractor'
require 'database_validations/lib/validations'
require 'database_validations/lib/errors'
require 'database_validations/lib/rescuer'
require 'database_validations/lib/injector'
require 'database_validations/lib/adapters'

module DatabaseValidations
  extend ActiveSupport::Concern
end

ActiveRecord::Base.include(DatabaseValidations) if defined?(ActiveRecord::Base)
