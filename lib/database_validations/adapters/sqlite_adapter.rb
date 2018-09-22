module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message].freeze
      ADAPTER = :sqlite

      def error_columns(error_message)
        error_message.scan(/#{model.table_name}\.([^,:]+)/).flatten
      end
    end
  end
end
