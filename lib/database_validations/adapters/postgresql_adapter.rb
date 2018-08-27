module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      def error_columns(error_message)
        index_name = error_message[/unique constraint "([^"]+)"/, 1]
        index_columns(index_name)
      end
    end
  end
end
