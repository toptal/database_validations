module DatabaseValidations
  module Helpers
    module_function

    def handle_unique_error!(instance, error)
      key = generate_key(Adapters.factory(instance.class).error_columns(error.message))

      each_options_storage(instance.class) do |storage|
        return storage[key].handle_unique_error(instance) if storage[key]
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
