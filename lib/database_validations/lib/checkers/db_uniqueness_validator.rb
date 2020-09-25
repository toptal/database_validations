module DatabaseValidations
  module Checkers
    class DbUniquenessValidator
      attr_reader :validator

      # @param [DatabaseValidations::DbUniquenessValidator]
      def self.validate!(validator)
        new(validator).validate!
      end

      # @param [DatabaseValidations::DbUniquenessValidator]
      def initialize(validator)
        @validator = validator
      end

      def validate!
        validate_index_usage!

        validate_indexes! unless ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']
      end

      private

      def valid_index?(columns, index)
        index_columns_size = index.columns.is_a?(Array) ? index.columns.size : (index.columns.count(',') + 1)

        (columns.size == index_columns_size) && (validator.where.nil? == index.where.nil?)
      end

      def validate_index_usage!
        return unless validator.index_name.present? && validator.attributes.size > 1

        raise ArgumentError, "When index_name is provided validator can have only one attribute. See #{validator.inspect}"
      end

      def validate_indexes! # rubocop:disable Metrics/AbcSize
        adapter = Adapters::BaseAdapter.new(validator.klass)

        validator.attributes.map do |attribute|
          columns = KeyGenerator.unify_columns(attribute, validator.options[:scope])
          index = validator.index_name ? adapter.find_unique_index_by_name(validator.index_name.to_s) : adapter.find_unique_index(columns, validator.where) # rubocop:disable Metrics/LineLength
          raise Errors::IndexNotFound.new(columns, validator.where, validator.index_name, adapter.unique_indexes, adapter.table_name) unless index && valid_index?(columns, index) # rubocop:disable Metrics/LineLength
        end
      end
    end
  end
end
