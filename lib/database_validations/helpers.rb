module DatabaseValidations
  module Helpers
    module_function

    def raise_if_index_missed!(model, columns)
      index = model.connection
                .indexes(model.table_name)
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

      attribute = instance.class.attribute_by_columns[columns]
      instance.errors.add(attribute, :taken, value: instance.public_send(attribute))
    end
  end
end
