module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      ADAPTER = :mysql2

      class << self
        def unique_index_name(error_message)
          error_message[/key '([^']+)'/, 1]
        end

        def unique_error_columns(_error_message); end

        def foreign_key_error_column(error_message)
          error_message[/FOREIGN KEY \(`([^`]+)`\)/, 1]
        end
      end
    end
  end
end
