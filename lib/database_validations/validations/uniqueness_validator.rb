module DatabaseValidations
  module UniquenessHandlers
    extend ActiveSupport::Concern

    included do
      alias_method :valid_without_uniqueness?, :valid?

      def valid?(context = nil)
        output = super(context)

        Helpers.each_validator(self.class) do |validator|
          if validator.if_and_unless_pass?(self)
            validates_with(ActiveRecord::Validations::UniquenessValidator, validator.validates_uniqueness_options)
          end
        end

        errors.empty? && output
      end

      alias_method :validate, :valid?
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
      options[:validate] == false || valid_without_uniqueness?(options[:context])
    end
  end

  module ClassMethods
    def validates_db_uniqueness_of(*attributes)
      @validates_db_uniqueness_opts ||= DatabaseValidations::UniquenessOptionsStorage.new(self)

      options = attributes.extract_options!

      attributes.each do |attribute|
        @validates_db_uniqueness_opts.push(attribute, options.merge(attributes: attribute))
      end

      include(DatabaseValidations::UniquenessHandlers)
    end
  end
end
