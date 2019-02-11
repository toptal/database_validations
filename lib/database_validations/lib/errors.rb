module DatabaseValidations
  module Errors
    class Base < StandardError
      def env_message
        "Use ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']=true in case you want to skip the check. For example, when you run migrations."
      end
    end

    class IndexNotFound < Base
      attr_reader :columns, :where_clause, :index_name, :available_indexes, :table_name

      def initialize(columns, where_clause, index_name, available_indexes, table_name)
        @columns = columns
        @where_clause = where_clause
        @available_indexes = available_indexes
        @index_name = index_name

        text = if index_name
                 "No unique index found with name: \"#{index_name}\" in table \"#{table_name}\". "\
                 "Available indexes are: #{self.available_indexes.map(&:name)}. "
               else
                 available_indexes = self.available_indexes.map { |ind| columns_and_where_text(ind.columns, ind.where) }.join(', ')
                 "No unique index found with #{columns_and_where_text(columns, where_clause)} in table \"#{table_name}\". "\
                 "Available indexes are: [#{available_indexes}]. "
               end

        super text + env_message
      end

      def columns_and_where_text(columns, where)
        "columns: #{columns}#{" and where: #{where}" if where}"
      end
    end

    class UnknownDatabase < Base
      attr_reader :database

      def initialize(database)
        @database = database
        super "Unknown database: #{self.database}"
      end
    end

    class OptionIsNotSupported < Base
      attr_reader :option, :database, :supported_options

      def initialize(option, database, supported_options)
        @option = option
        @database = database
        @supported_options = supported_options
        super "Option #{self.option} is not supported for #{self.database}. Supported options are: #{self.supported_options}"
      end
    end

    class ForeignKeyNotFound < Base
      attr_reader :column, :foreign_keys

      def initialize(column, foreign_keys)
        @column = column
        @foreign_keys = foreign_keys

        super "No foreign key found with column: \"#{column}\". Founded foreign keys are: #{foreign_keys}. " + env_message
      end
    end

    class UnsupportedDatabase < Base
      attr_reader :database, :method

      def initialize(method, database)
        @database = database
        @method = method
        super "Database #{database} doesn't support #{method}"
      end
    end
  end
end
