module DatabaseValidations
  module Adapters
    class PostgresqlAdapter < BaseAdapter
      ADAPTER = :postgresql

      class << self
        def unique_index_name(error)
          error.message[/unique constraint "([^"]+)"/, 1]
        end

        # PostgreSQL leaves the `DETAIL:  Key (...)=(...) already exists.` line out of a unique violation on a
        # table the current role is subject to row-level security on, because the values could belong to a row the
        # role cannot see. The columns are then unknown (nil) and the error is matched by its index name instead.
        def unique_error_columns(error)
          error.message[/Key \((.+)\)=/, 1]&.split(', ')
        end

        # A composite key reports every column, `Key (tenant_id, company_id)=(1, 2)`; each is a candidate, and the
        # rescuer picks the one with a matching `db_belongs_to`.
        def foreign_key_error_column(error)
          columns = error.message[/Key \(([^)]+)\)/, 1]
          columns ? columns.split(', ') : []
        end
      end
    end
  end
end
