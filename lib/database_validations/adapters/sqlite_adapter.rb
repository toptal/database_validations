module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      def columns(error_message)
        error_message.scan(/entities\.([^,:]+)/).flatten
      end
    end
  end
end
