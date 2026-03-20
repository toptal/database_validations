module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      ADAPTER = :postgresql

      class << self
        def unique_index_name(error)
          error.message[/unique constraint "([^"]+)"/, 1]
        end

        def unique_error_columns(error)
          error.message[/Key \((.+)\)=/, 1].split(', ')
        end

        def foreign_key_error_column(error)
          column = error.message[/Key \(([^)]+)\)/, 1]
          column ? [column] : []
        end
      end
    end
  end
end
