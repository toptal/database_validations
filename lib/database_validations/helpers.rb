module DatabaseValidations
  module Helpers
    module_function

    def check_unique_index!(model, columns)
      index = model.connection.indexes(model.table_name).select(&:unique).find { |index| index.columns.map(&:to_s).sort == columns }
      raise Errors::IndexNotFound.new(columns) unless index
    end

    def unique_field(model, columns)
      columns.map!(&:to_s).sort!

      validator = model.validates_db_uniqueness.find do |options|
        options[:columns] == columns
      end

      validator[:field] if validator
    end

    def handle_unique_error(instance, error)
      columns = DatabaseValidations::Adapters.factory(instance.class).error_columns(error.message)
      field = DatabaseValidations::Helpers.unique_field(instance.class, columns)
      instance.errors.add(field, :taken, value: instance.public_send(field))
    end
  end
end
