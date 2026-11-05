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

        keys = foreign_key_columns(instance, error).map { |column| KeyGenerator.for_db_presence(column) }
        process_keys(validate, instance, keys)
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

    # The columns the error names, or, where the message leaves them out, the columns of the constraint it names.
    def foreign_key_columns(instance, error)
      adapter = Adapters.factory(instance.class)
      columns = adapter.foreign_key_error_column(error)
      return columns if columns.any? || !adapter.respond_to?(:foreign_key_error_constraint)

      key = foreign_key_named(instance, adapter.foreign_key_error_constraint(error))
      key ? Array(key.column).map(&:to_s) : []
    end

    def foreign_key_named(instance, name)
      name && instance.class.connection.foreign_keys(instance.class.table_name).find { |key| key.name == name }
    end

    def process(validate, instance, error, key_types)
      process_keys(validate, instance, resolve_keys(instance, error, key_types))
    end

    def process_keys(validate, instance, keys)
      attribute_validator = find_matching_validator(instance, keys)
      return false unless attribute_validator

      process_validator(validate, instance, attribute_validator)
    end

    def resolve_keys(instance, error, key_types)
      adapter = Adapters.factory(instance.class)

      # Uniqueness adapters return the columns of a single composite key, passed together to the key generator. A
      # foreign key's candidate columns each make a key of their own (`foreign_key_columns`).
      key_types.map do |key_generator, error_processor|
        KeyGenerator.public_send(key_generator, adapter.public_send(error_processor, error))
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
