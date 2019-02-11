module DatabaseValidations
  class DBUniquenessValidator < ActiveRecord::Validations::UniquenessValidator
    # This is a hack to simulate presence validator
    # It's used for cases when some 3rd parties are relies on the validators
    # For example, +required+ option from simple_form checks the validator
    def self.kind
      :uniqueness
    end

    def validate(record)
      super if record._database_validations_fallback
    end
  end
end
