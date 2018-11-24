module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message if unless].freeze
      ADAPTER = :sqlite3

      def index_name(_error_message)
      end

      def find_foreign_key_by_column(column)
        foreign_keys.find { |foreign_key| foreign_key.column.to_s == column.to_s }
      end

      def unique_error_columns(error_message)
        error_message.scan(/#{model.table_name}\.([^,:]+)/).flatten
      end

      def foreign_key_error_column(error_message)
        error_message[/\("([^"]+)"\) VALUES/, 1]
      end
    end
  end
end
