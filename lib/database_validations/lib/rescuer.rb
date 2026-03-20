module DatabaseValidations
  module Rescuer
    module_function

    def handled?(instance, error, validate)
      Storage.prepare(instance.class) unless Storage.prepared?(instance.class)

      case error
      when ActiveRecord::RecordNotUnique
        process(validate, instance, error, for_unique_index: :unique_index_name, for_db_uniqueness: :unique_error_columns)
      when ActiveRecord::InvalidForeignKey
        process(validate, instance, error, for_db_presence: :foreign_key_error_column)
      else false
      end
    end

    def process(validate, instance, error, key_types)
      adapter = Adapters.factory(instance.class)

      keys = key_types.flat_map do |key_generator, error_processor|
        result = adapter.public_send(error_processor, error)

        # FK adapters return an array of candidate columns, each generating a
        # separate key. Uniqueness adapters return columns that form a single
        # composite key, passed together to the key generator.
        if key_generator == :for_db_presence
          Array(result).map { |column| KeyGenerator.public_send(key_generator, column) }
        else
          [KeyGenerator.public_send(key_generator, result)]
        end
      end

      first_match = nil

      keys.each do |key|
        attribute_validator = instance._db_validators[key]
        next unless attribute_validator

        first_match ||= attribute_validator

        if keys.size > 1
          next unless foreign_key_invalid?(instance, attribute_validator)
        end

        return process_validator(validate, instance, attribute_validator)
      end

      # TOCTOU fallback: if disambiguate queries all passed (concurrent insert),
      # use the first matching validator rather than leaving the error unhandled.
      return process_validator(validate, instance, first_match) if first_match

      false
    end

    def foreign_key_invalid?(instance, attribute_validator)
      attribute = attribute_validator.attribute
      reflection = instance.class._reflect_on_association(attribute)
      return true unless reflection

      fk_value = instance.read_attribute(reflection.foreign_key)
      return true if fk_value.blank?

      !reflection.klass.exists?(reflection.association_primary_key => fk_value)
    end

    def process_validator(validate, instance, attribute_validator)
      return false unless attribute_validator.validator.perform_rescue?(validate)

      attribute_validator.validator.apply_error(instance, attribute_validator.attribute)
      true
    end
  end
end
