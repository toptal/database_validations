module DatabaseValidations
  module Helpers
    module_function

    def check_unique_index!(model, columns, scope)
      columns.each do |column|
        index_columns = [column, scope].flatten.map(&:to_s)
        index = model.connection.indexes(model.table_name).select(&:unique).find { |index| index.columns.map(&:to_s).sort == index_columns.sort }
        raise Errors::IndexNotFound.new(index_columns) unless index
      end
    end

    def field(model, columns)
      columns.map!(&:to_s).sort!

      validation = model.validates_db_uniqueness.find do |options|
        options[:columns] == columns
      end

      validation[:field] if validation
    end
  end
end
