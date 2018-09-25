module DatabaseValidations
  module Errors
    class Base < StandardError; end

    class IndexNotFound < Base
      attr_reader :columns, :where_clause, :available_indexes

      def initialize(columns, where_clause, available_indexes)
        @columns = columns.map(&:to_s)
        @where_clause = where_clause
        @available_indexes = available_indexes

        super "No unique index found with #{columns_and_where_text(columns, where_clause)}. "\
              "Available indexes are: [#{self.available_indexes.map { |ind| columns_and_where_text(ind.columns, ind.where) }.join(', ')}]. "\
              "Use ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']=true in case you want to skip the check. "\
              "For example, when you run migrations."
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
  end
end
