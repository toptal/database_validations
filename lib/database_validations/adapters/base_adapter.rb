module DatabaseValidations
  module Adapters
    class BaseAdapter
      SUPPORTED_OPTIONS = [].freeze
      ADAPTER = :base

      def initialize(model)
        @model = model
      end

      def find_index_by_name(index_name)
        indexes.find { |index| index.name == index_name }
      end

      def find_index(columns, where)
        indexes.find { |index| index.columns.map(&:to_s).sort == columns && index.where == where }
      end

      def indexes
        model.connection.indexes(model.table_name).select(&:unique)
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

      private

      attr_reader :model
    end
  end
end
