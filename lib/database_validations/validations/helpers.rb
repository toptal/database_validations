module DatabaseValidations
  module Helpers
    module_function

    def handle_unique_error!(instance, error)
      adapter = Adapters.factory(instance.class)
      index_key = adapter.index_name(error.message)
      column_key = generate_key(adapter.error_columns(error.message))

      each_options_storage(instance.class) do |storage|
        return storage[index_key].handle_unique_error(instance) if storage[index_key]
        return storage[column_key].handle_unique_error(instance) if storage[column_key]
      end

      raise error
    end

    def each_options_storage(klass)
      while klass.respond_to?(:validates_db_uniqueness_of)
        storage = klass.instance_variable_get(:'@validates_db_uniqueness_opts')
        yield(storage) if storage
        klass = klass.superclass
      end
    end

    def each_validator(klass)
      each_options_storage(klass) do |storage|
        storage.each_validator { |validator| yield(validator) }
      end
    end

    def unify_columns(*columns)
      columns.flatten.compact.map(&:to_s).sort
    end

    def generate_key(*columns)
      unify_columns(columns).join('__')
    end
  end
end
