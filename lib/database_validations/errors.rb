module DatabaseValidations
  module Errors
    class Base < StandardError; end

    class IndexNotFound < Base
      attr_reader :columns

      def initialize(columns)
        @columns = columns.map(&:to_s)
        super "No unique index found with columns: #{self.columns}. "\
              "Use ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']=true in case you want to skip the check. "\
              "For example, when you run migrations."
      end
    end

    class UnknownDatabase < Base
      attr_reader :database

      def initialize(database)
        @database = database
        super "Unknown database: #{self.database}"
      end
    end
  end
end
