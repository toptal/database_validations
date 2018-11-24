module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message if unless index_name].freeze
      ADAPTER = :mysql2

      def index_name(error_message)
        error_message[/key '([^']+)'/, 1]
      end

      def unique_error_columns(error_message)
        find_index_by_name(index_name(error_message)).columns
      end

      def foreign_key_error_column(error_message)
        error_message[/FOREIGN KEY \(`([^`]+)`\)/, 1]
      end
    end
  end
end
