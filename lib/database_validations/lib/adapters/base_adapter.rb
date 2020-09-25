module DatabaseValidations
  module Adapters
    class BaseAdapter
      SUPPORTED_OPTIONS = [].freeze
      ADAPTER = :base

      def initialize(model)
        @model = model
      end

      # @param [String] index_name
      def find_unique_index_by_name(index_name)
        unique_indexes.find { |index| index.name == index_name }
      end

      # @param [Array<String>] columns
      # @param [String] where
      def find_unique_index(columns, where)
        unique_indexes.find { |index| Array.wrap(index.columns).map(&:to_s).sort == columns && index.where == where }
      end

      def unique_indexes
        connection = model.connection

        if connection.schema_cache.respond_to?(:indexes)
          # Rails 6 only
          connection.schema_cache.indexes(model.table_name).select(&:unique)
        else
          connection.indexes(model.table_name).select(&:unique)
        end
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
