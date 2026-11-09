module DatabaseValidations
  module Adapters
    class SqliteAdapter < BaseAdapter
      ADAPTER = :sqlite3

      class << self
        def unique_index_name(error)
          error.message[/UNIQUE constraint failed: index '([^']+)'/, 1]
        end

        def unique_error_columns(error)
          error.message.scan(/\w+\.([^,:]+)/).flatten
        end

        # SQLite's message names no table; the failed statement does.
        def foreign_key_error_table(error)
          return unless error.respond_to?(:sql) && error.sql

          error.sql[/\A\s*(?:INSERT\s+INTO|UPDATE)\s+"?([^"\s(]+)"?/i, 1]
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
