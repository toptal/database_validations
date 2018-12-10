module DatabaseValidations
  module Helpers
    module_function

    def handle_unique_error!(instance, error) # rubocop:disable Metrics/AbcSize
      adapter = Adapters.factory(instance.class)
      index_key = generate_key_for_uniqueness_index(adapter.index_name(error.message))
      column_key = generate_key_for_uniqueness(adapter.unique_error_columns(error.message))

      each_options_storage(instance.class) do |storage|
        return storage[index_key].handle_unique_error(instance) if storage[index_key]
        return storage[column_key].handle_unique_error(instance) if storage[column_key]
      end

      raise error
    end

    def handle_foreign_key_error!(instance, error)
      adapter = Adapters.factory(instance.class)
      column_key = generate_key_for_belongs_to(adapter.foreign_key_error_column(error.message))

      each_options_storage(instance.class) do |storage|
        return storage[column_key].handle_foreign_key_error(instance) if storage[column_key]
      end

      raise error
    end

    def check_foreign_key_missing(instance)
      Helpers.each_belongs_to_presence_validator(instance.class) do |validator|
        if instance.public_send(validator.column).nil? && instance.public_send(validator.relation).nil?
          instance.errors.add(validator.relation, :blank, message: :required)
        end
      end
      instance.errors.empty?
    end

    def each_options_storage(klass)
      while klass.respond_to?(:validates_db_uniqueness_of)
        storage = klass.instance_variable_get(:'@database_validations_opts')
        yield(storage) if storage
        klass = klass.superclass
      end
    end

    def each_uniqueness_validator(klass)
      each_options_storage(klass) do |storage|
        storage.each_uniqueness_validator { |validator| yield(validator) }
      end
    end

    def each_belongs_to_presence_validator(klass)
      each_options_storage(klass) do |storage|
        storage.each_belongs_to_presence_validator { |validator| yield(validator) }
      end
    end

    def unify_columns(*columns)
      columns.flatten.compact.map(&:to_s).sort
    end

    def generate_key_for_uniqueness_index(index_name)
      generate_key(:uniqueness_index, index_name)
    end

    def generate_key_for_uniqueness(*columns)
      generate_key(:uniqueness, columns)
    end

    def generate_key_for_belongs_to(column)
      generate_key(:belongs_to, column)
    end

    def generate_key(type, *columns)
      [type, *unify_columns(columns)].join('__')
    end
  end
end
