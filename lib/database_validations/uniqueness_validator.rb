module DatabaseValidations
  module DatabaseUniquenessValidator
    extend ActiveSupport::Concern

    included do
      alias_method :valid_without_uniqueness?, :valid?

      def valid?(context = nil)
        output = super(context)

        self.class.validates_db_uniqueness.each_value do |opts|
          validates_with(ActiveRecord::Validations::UniquenessValidator, opts.merge(allow_nil: true))
        end

        errors.empty? && output
      end

      alias_method :validate, :valid?
    end

    def save(options = {})
      super
    rescue ActiveRecord::RecordNotUnique => e
      DatabaseValidations::Helpers.handle_unique_error(self, e)
      false
    end

    def save!(options = {})
      super
    rescue ActiveRecord::RecordNotUnique => e
      DatabaseValidations::Helpers.handle_unique_error(self, e)
      raise ActiveRecord::RecordInvalid, self
    end

    private

    def perform_validations(options = {})
      options[:validate] == false || valid_without_uniqueness?(options[:context])
    end
  end

  module ClassMethods
    def validates_db_uniqueness_of(*attributes)
      @validates_db_uniqueness ||= {}

      options = attributes.extract_options!

      attributes.each do |attribute|
        columns = [attribute, Array.wrap(options[:scope])].flatten!.map!(&:to_s).sort!

        DatabaseValidations::Helpers.raise_if_index_missed!(self, columns)

        @validates_db_uniqueness[columns] = options.merge(attributes: attribute)
      end

      include(DatabaseUniquenessValidator)
    end

    def validates_db_uniqueness
      derived = superclass.respond_to?(:validates_db_uniqueness) ? superclass.validates_db_uniqueness : {}
      derived.merge(@validates_db_uniqueness || {})
    end
  end
end
