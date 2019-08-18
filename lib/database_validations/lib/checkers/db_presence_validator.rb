module DatabaseValidations
  module Checkers
    class DbPresenceValidator
      attr_reader :validator

      # @param [DatabaseValidations::DbPresenceValidator]
      def self.validate!(validator)
        new(validator).validate!
      end

      # @param [DatabaseValidations::DbPresenceValidator]
      def initialize(validator)
        @validator = validator
      end

      def validate!
        validate_foreign_keys! unless ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']
      end

      private

      def validate_foreign_keys! # rubocop:disable Metrics/AbcSize
        adapter = Adapters::BaseAdapter.new(validator.klass)

        validator.attributes.each do |attribute|
          reflection = validator.klass._reflect_on_association(attribute)

          next unless reflection
          next if adapter.find_foreign_key_by_column(reflection.foreign_key)

          raise Errors::ForeignKeyNotFound.new(reflection.foreign_key, adapter.foreign_keys)
        end
      end
    end
  end
end
