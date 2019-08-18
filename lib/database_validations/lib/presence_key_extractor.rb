module DatabaseValidations
  module PresenceKeyExtractor
    module_function

    # @param [DatabaseValidations::DbPresenceValidator]
    #
    # @return [Hash]
    def attribute_by_key(validator)
      validator.attributes.map do |attribute|
        reflection = validator.klass._reflect_on_association(attribute)

        key = reflection ? reflection.foreign_key : attribute

        [KeyGenerator.for_db_presence(key), attribute]
      end.to_h
    end
  end
end
