module DatabaseValidations
  module Adapters
    class MysqlAdapter < BaseAdapter
      def error_columns(error_message)
        index_name = error_message[/key '([^']+)'/, 1]
        index_columns(index_name)
      end
    end
  end
end
