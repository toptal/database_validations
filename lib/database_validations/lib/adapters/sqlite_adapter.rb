module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      ADAPTER = :sqlite3

      class << self
        def unique_index_name(_error_message); end

        def unique_error_columns(error_message)
          error_message.scan(/\w+\.([^,:]+)/).flatten
        end

        def foreign_key_error_column(error_message)
          error_message[/\("([^"]+)"\) VALUES/, 1]
        end
      end
    end
  end
end
