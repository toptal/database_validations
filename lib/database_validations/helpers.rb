module DatabaseValidations
  module Helpers
    module_function

    def raise_if_index_missed!(model, columns)
      connection = model.connection rescue return
      index = connection.indexes(model.table_name)
                .select(&:unique)
                .find { |index| index.columns.map(&:to_s).sort == columns }

      raise Errors::IndexNotFound.new(columns) unless index
    end

    def handle_unique_error(instance, error)
      columns = DatabaseValidations::Adapters
                  .factory(instance.class)
                  .error_columns(error.message)
                  .map!(&:to_s)
                  .sort!

      options = uniqueness_validators_options(instance.class)[columns]

      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end

    def uniqueness_validators_options(klass)
      validators_options = klass.instance_variable_get(:'@validates_db_uniqueness_opts') || {}

      while klass.superclass.respond_to?(:validates_db_uniqueness_of)
        validators_options.reverse_merge!(klass.superclass.instance_variable_get(:'@validates_db_uniqueness_opts') || {})
        klass = klass.superclass
      end

      validators_options
    end
  end
end
