module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message if unless].freeze
      ADAPTER = :sqlite3

      def error_columns(error_message)
        error_message.scan(/#{model.table_name}\.([^,:]+)/).flatten
      end
    end
  end
end
