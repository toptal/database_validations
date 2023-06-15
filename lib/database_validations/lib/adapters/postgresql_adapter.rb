module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      ADAPTER = :postgresql
      POSTGIS_ADAPTER = :postgis

      class << self
        def unique_index_name(error_message)
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
end
