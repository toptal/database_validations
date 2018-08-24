module DatabaseValidations
  module Errors
    class Base < StandardError; end

    class IndexNotFound < Base
      attr_reader :columns

      def initialize(columns)
        @columns = columns.map(&:to_s)
        super "No unique index found with columns: #{self.columns}"
      end
    end
  end
end
