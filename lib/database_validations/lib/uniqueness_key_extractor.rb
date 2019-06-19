module DatabaseValidations
  module UniquenessKeyExtractor
    module_function

    # @param [DatabaseValidations::DbUniquenessValidator]
    #
    # @return [Hash]
    def attribute_by_columns_keys(validator)
      validator.attributes.map do |attribute|
        [KeyGenerator.for_db_uniqueness(attribute, Array.wrap(validator.options[:scope])), attribute]
      end.to_h
    end

    # @param [DatabaseValidations::DbUniquenessValidator]
    #
    # @return [Hash]
    def attribute_by_indexes_keys(validator) # rubocop:disable Metrics/AbcSize
      adapter = Adapters::BaseAdapter.new(validator.klass)

      if validator.index_name
        [[KeyGenerator.for_unique_index(validator.index_name), validator.attributes[0]]].to_h
      else
        validator.attributes.map do |attribute|
          columns = KeyGenerator.unify_columns(attribute, validator.options[:scope])
          index = adapter.find_index(columns, validator.where)
          [KeyGenerator.for_unique_index(index.name), attribute]
        end.to_h
      end
    end

    # @param [DatabaseValidations::DbUniquenessValidator]
    #
    # @return [Hash]
    def attribute_by_key(validator)
      attribute_by_columns_keys(validator).merge(attribute_by_indexes_keys(validator))
    end
  end
end
