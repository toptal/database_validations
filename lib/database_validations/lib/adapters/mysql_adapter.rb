module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      ADAPTER = :mysql2

      class << self
        def unique_index_name(error)
          error.message[/key '([^']+)'/, 1]&.split('.')&.last
        end

        def unique_error_columns(_error); end

        def foreign_key_error_column(error)
          column = error.message[/FOREIGN KEY \(`([^`]+)`\)/, 1]
          column ? [column] : []
        end
      end
    end
  end
end
