module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message where if unless index_name case_sensitive].freeze
      ADAPTER = :postgresql

      def index_name(error_message)
        error_message[/unique constraint "([^"]+)"/, 1]
      end

      def error_columns(error_message)
        find_index_by_name(index_name(error_message)).columns
      end
    end
  end
end
