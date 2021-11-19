module DatabaseValidations
  module Validations
    extend ActiveSupport::Concern

    included do
      alias_method :validate, :valid?
    end

    attr_accessor :_database_validations_fallback

    def valid?(context = nil)
      self._database_validations_fallback = true
      super(context)
    end

    def create_or_update(*args, &block)
      options = args.extract_options!
      rescue_from_database_exceptions(options[:validate]) { super }
    end

    private

    def rescue_from_database_exceptions(validate, &block)
      self._database_validations_fallback = false
      self.class.connection.transaction(requires_new: true, &block)
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotUnique => e
      raise e unless Rescuer.handled?(self, e, validate)

      raise ActiveRecord::RecordInvalid, self
    end

    def perform_validations(options = {})
      options[:validate] == false || valid_without_database_validations?(options[:context])
    end
  end
end
