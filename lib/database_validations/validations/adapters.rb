require 'database_validations/validations/adapters/base_adapter'
require 'database_validations/validations/adapters/sqlite_adapter'
require 'database_validations/validations/adapters/postgresql_adapter'
require 'database_validations/validations/adapters/mysql_adapter'

module DatabaseValidations
  module Adapters
    module_function

    def factory(model)
      case (database = model.connection_config[:adapter].downcase.to_sym)
      when SqliteAdapter::ADAPTER then SqliteAdapter.new(model)
      when PostgresqlAdapter::ADAPTER then PostgresqlAdapter.new(model)
      when MysqlAdapter::ADAPTER then MysqlAdapter.new(model)
      else
        raise Errors::UnknownDatabase, database
      end
    end
  end
end
