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

      options = instance.class.validates_db_uniqueness[columns]

      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end
  end
end
