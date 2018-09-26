module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message where if unless].freeze
      ADAPTER = :postgresql

      def error_columns(error_message)
        index_name = error_message[/unique constraint "([^"]+)"/, 1]
        find_index_by_name(index_name).columns
      end
    end
  end
end
