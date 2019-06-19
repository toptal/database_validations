module DatabaseValidations
  module Adapters
    class BaseAdapter
      SUPPORTED_OPTIONS = [].freeze
      ADAPTER = :base

      def initialize(model)
        @model = model
      end

      # @param [String] index_name
      def find_index_by_name(index_name)
        indexes.find { |index| index.name == index_name }
      end

      # @param [Array<String>] columns
      # @param [String] where
      def find_index(columns, where)
        indexes.find { |index| Array.wrap(index.columns).map(&:to_s).sort == columns && index.where == where }
      end

      def indexes
        model.connection.indexes(model.table_name).select(&:unique)
      end

      def foreign_keys
        model.connection.foreign_keys(model.table_name)
      end

      def find_foreign_key_by_column(column)
        foreign_keys.find { |foreign_key| foreign_key.column.to_s == column.to_s }
      end

      # @return [String]
      def table_name
        model.table_name
      end

      private

      attr_reader :model
    end
  end
end
