require 'database_validations/adapters/base_adapter'
require 'database_validations/adapters/sqlite_adapter'

module DatabaseValidations
  module Adapters
    module_function

    def factory(model)
      case (database = model.connection.adapter_name.downcase.to_sym)
      when :sqlite then Adapters::SqliteAdapter.new(model)
      else
        raise Errors::UnknownDatabase.new(database)
      end
    end
  end
end
