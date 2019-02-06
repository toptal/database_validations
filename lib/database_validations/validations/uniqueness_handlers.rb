module DatabaseValidations
  module UniquenessHandlers
    extend ActiveSupport::Concern

    included do
      alias_method :validate, :valid?
    end

    def valid?(context = nil)
      output = super(context)

      Helpers.each_uniqueness_validator(self.class) do |validator|
        if validator.if_and_unless_pass?(self)
          validates_with(ActiveRecord::Validations::UniquenessValidator, validator.validates_uniqueness_options)
        end
      end

      errors.empty? && output
    end

    def save(options = {})
      ActiveRecord::Base.connection.transaction(requires_new: true) { super }
    rescue ActiveRecord::RecordNotUnique => e
      Helpers.handle_unique_error!(self, e)
      false
    end

    def save!(options = {})
      ActiveRecord::Base.connection.transaction(requires_new: true) { super }
    rescue ActiveRecord::RecordNotUnique => e
      Helpers.handle_unique_error!(self, e)
      raise ActiveRecord::RecordInvalid, self
    end

    private

    def perform_validations(options = {})
      options[:validate] == false || valid_without_database_validations?(options[:context])
    end
  end

  module ClassMethods
    def validates_db_uniqueness_of(*attributes)
      include(DatabaseValidations::ValidWithoutDatabaseValidations)
      @database_validations_opts ||= DatabaseValidations::OptionsStorage.new(self)

      options = attributes.extract_options!

      attributes.each do |attribute|
        @database_validations_opts.push_uniqueness(attribute, options.merge(attributes: attribute))
      end

      include(DatabaseValidations::UniquenessHandlers)
    end
  end
end
