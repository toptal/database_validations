module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      ADAPTER = :sqlite3

      class << self
        def unique_index_name(_error); end

        def unique_error_columns(error)
          error.message.scan(/\w+\.([^,:]+)/).flatten
        end

        def foreign_key_error_column(error)
          return [] unless error.respond_to?(:sql) && error.sql

          columns_clause = error.sql[/\(([^)]+)\)\s*VALUES/i, 1]
          return [] unless columns_clause

          columns_clause.scan(/"([^"]+)"/).flatten
        end
      end
    end
  end
end
