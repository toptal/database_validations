module DatabaseValidations
  module Rescuer
    module_function

    def handled?(instance, error, validate)
      Storage.prepare(instance.class) unless Storage.prepared?(instance.class)

      case error
      when ActiveRecord::RecordNotUnique
        process(validate, instance, error, for_unique_index: :unique_index_name, for_db_uniqueness: :unique_error_columns)
      when ActiveRecord::InvalidForeignKey
        return false unless own_table?(instance, error)

        process(validate, instance, error, for_db_presence: :foreign_key_error_column)
      else false
      end
    end

    # A foreign key of another table, a child saved along with the instance, is not the instance's to report: a
    # composite key shares columns with the instance's own associations (`tenant_id`), so matching by column alone
    # would pin the child's failure on one of them. A table the adapter cannot read is not ruled out.
    def own_table?(instance, error)
      table = Adapters.factory(instance.class).foreign_key_error_table(error)
      table.nil? || table == instance.class.table_name.to_s.split('.').last
    end

    def process(validate, instance, error, key_types)
      keys = resolve_keys(instance, error, key_types)
      attribute_validator = find_matching_validator(instance, keys)
      return false unless attribute_validator

      process_validator(validate, instance, attribute_validator)
    end

    def resolve_keys(instance, error, key_types)
      adapter = Adapters.factory(instance.class)

      key_types.flat_map do |key_generator, error_processor|
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
    end

    def find_matching_validator(instance, keys)
      last_match = nil

      keys.each do |key|
        attribute_validator = instance._db_validators[key]
        next unless attribute_validator

        last_match = attribute_validator

        next if (keys.size > 1) && !foreign_key_invalid?(instance, attribute_validator)

        return attribute_validator
      end

      # Every candidate's row exists: the key refuses the combination, as a composite key that leads with a tenant
      # column does for a parent of another tenant, or a concurrent change removed the row (TOCTOU). The last
      # matching column is the parent's in such a key, not the tenant's, so its association gets the error.
      last_match
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
