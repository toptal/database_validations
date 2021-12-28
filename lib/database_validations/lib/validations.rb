module DatabaseValidations
  module Validations
    extend ActiveSupport::Concern

    included do
      alias_method :validate, :valid?
    end

    class_methods do
      def create_or_find_by!(attributes, &block)
        super
      rescue ActiveRecord::RecordInvalid => e
        rescue_create_or_find_by_uniqueness_exception(e, attributes)
      end

      def create_or_find_by(attributes, &block)
        super
      rescue ActiveRecord::RecordInvalid => e
        rescue_create_or_find_by_uniqueness_exception(e, attributes)
      end

      private

      def rescue_create_or_find_by_uniqueness_exception(err, attributes)
        raise err unless err.cause&.is_a?(ActiveRecord::RecordNotUnique)

        find_by!(attributes)
      end
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
