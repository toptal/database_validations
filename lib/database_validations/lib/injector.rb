module DatabaseValidations
  module Injector
    module_function

    # @param [ActiveRecord::Base] model
    def inject(model)
      return if model.method_defined?(:valid_without_database_validations?)

      model.__send__(:alias_method, :valid_without_database_validations?, :valid?)
      model.include(DatabaseValidations::Validations)
    end
  end
end
