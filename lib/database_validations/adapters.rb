require 'database_validations/adapters/base_adapter'
require 'database_validations/adapters/sqlite_adapter'
require 'database_validations/adapters/postgresql_adapter'
require 'database_validations/adapters/mysql_adapter'

module DatabaseValidations
  module Adapters
    module_function

    def factory(model)
      case (database = model.connection.adapter_name.downcase.to_sym)
      when SqliteAdapter::ADAPTER then SqliteAdapter.new(model)
      when PostgresqlAdapter::ADAPTER then PostgresqlAdapter.new(model)
      when MysqlAdapter::ADAPTER then MysqlAdapter.new(model)
      else
        raise Errors::UnknownDatabase.new(database)
      end
    end
  end
end
