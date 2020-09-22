module DatabaseValidations
  module Rescuer
    module_function

    def handled?(instance, error)
      Storage.prepare(instance.class) unless Storage.prepared?(instance.class)

      case error
      when ActiveRecord::RecordNotUnique
        process(instance, error, for_unique_index: :unique_index_name, for_db_uniqueness: :unique_error_columns)
      when ActiveRecord::InvalidForeignKey
        process(instance, error, for_db_presence: :foreign_key_error_column)
      else false
      end
    end

    def process(instance, error, key_types)
      adapter = Adapters.factory(instance.class)

      keys = key_types.map do |key_generator, error_processor|
        KeyGenerator.public_send(key_generator, adapter.public_send(error_processor, error.message))
      end

      keys.each do |key|
        attribute_validator = instance._db_validators[key]

        next unless attribute_validator

        return process_validator(instance, attribute_validator)
      end

      false
    end

    def process_validator(instance, attribute_validator)
      return false unless attribute_validator.validator.perform_db_validation?

      attribute_validator.validator.apply_error(instance, attribute_validator.attribute)
      true
    end
  end
end
