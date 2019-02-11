module DatabaseValidations
  module ClassMethods
    def validates_db_uniqueness_of(*attributes)
      Helpers.cache_valid_method!(self)

      @database_validations_opts ||= DatabaseValidations::OptionsStorage.new(self)

      options = attributes.extract_options!

      attributes.each do |attribute|
        @database_validations_opts.push_uniqueness(attribute, options.merge(attributes: attribute))
      end

      validates_with DatabaseValidations::DBUniquenessValidator,
                     DatabaseValidations::UniquenessOptions.validator_options(attributes, options)

      include(DatabaseValidations::Rescuer)
    end
  end
end
