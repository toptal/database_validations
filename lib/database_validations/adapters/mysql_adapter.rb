module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      SUPPORTED_OPTIONS = %i[scope message].freeze
      ADAPTER = :mysql2

      def error_columns(error_message)
        index_name = error_message[/key '([^']+)'/, 1]
        find_index_by_name(index_name).columns
      end
    end
  end
end
