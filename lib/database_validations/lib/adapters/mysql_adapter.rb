module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message if unless index_name].freeze
      ADAPTER = :mysql2

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
