module DatabaseValidations
  module ValidWithoutDatabaseValidations
    extend ActiveSupport::Concern

    included do
      alias_method :valid_without_database_validations, :valid?
    end
  end
end
