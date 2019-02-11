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
        model.connection.foreign_key_exists?(model.table_name, column: column)
      end

      # @return [Symbol]
      def adapter_name
        self.class::ADAPTER
      end

      # @param [Symbol] option_name
      # @return [Boolean]
      def support_option?(option_name)
        supported_options.include?(option_name.to_sym)
      end

      # @return [Array<Symbol>]
      def supported_options
        self.class::SUPPORTED_OPTIONS
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
