module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message where if unless index_name case_sensitive].freeze
      ADAPTER = :postgresql

      def index_name(error_message)
        error_message[/unique constraint "([^"]+)"/, 1]
      end

      def unique_error_columns(error_message)
        error_message[/Key \((.+)\)=/, 1].split(', ')
      end

      def foreign_key_error_column(error_message)
        error_message[/Key \(([^)]+)\)/, 1]
      end
    end
  end
end
