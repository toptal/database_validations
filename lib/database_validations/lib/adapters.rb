require 'database_validations/lib/adapters/base_adapter'
require 'database_validations/lib/adapters/sqlite_adapter'
require 'database_validations/lib/adapters/postgresql_adapter'
require 'database_validations/lib/adapters/mysql_adapter'

module DatabaseValidations
  module Adapters
    module_function

    def factory(model)
      case (database = model.connection_config[:adapter].downcase.to_sym)
      when SqliteAdapter::ADAPTER then SqliteAdapter
      when PostgresqlAdapter::ADAPTER then PostgresqlAdapter
      when MysqlAdapter::ADAPTER then MysqlAdapter
      else
        raise Errors::UnknownDatabase, database
      end
    end
  end
end
