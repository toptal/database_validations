module DatabaseValidations
  module Storage
    module_function

    def prepare(model)
      model.class_attribute :_db_validators, instance_writer: false
      model._db_validators = {}

      model.validators.each do |validator|
        case validator
        when DbUniquenessValidator then process(validator, UniquenessKeyExtractor, model)
        when DbPresenceValidator then process(validator, PresenceKeyExtractor, model)
        else next
        end
      end
    end

    def process(validator, extractor, model)
      extractor.attribute_by_key(validator).each do |key, attribute|
        model._db_validators[key] = AttributeValidator.new(attribute, validator)
      end
    end

    def prepared?(model)
      model.respond_to?(:_db_validators)
    end
  end
end
