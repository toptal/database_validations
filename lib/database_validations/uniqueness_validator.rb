module DatabaseValidations
  module DatabaseUniquenessValidator
    extend ActiveSupport::Concern

    included do
      alias_method :valid_without_uniqueness?, :valid?

      def valid?(context = nil)
        output = super(context)

        self.class.validates_db_uniqueness.each do |opts|
          validates_with(ActiveRecord::Validations::UniquenessValidator, opts)
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
      @validates_db_uniqueness ||= []
      @attribute_by_columns ||= {}

      options = attributes.extract_options!

      @validates_db_uniqueness.concat(attributes.map do |attribute|
        columns = [attribute, Array.wrap(options[:scope])].flatten!.map!(&:to_s).sort!

        DatabaseValidations::Helpers.raise_if_index_missed!(self, columns)
        @attribute_by_columns[columns] = attribute

        options.merge(attributes: attribute)
      end)

      include(DatabaseUniquenessValidator)
    end

    def attribute_by_columns
      derived = superclass.respond_to?(:attribute_by_columns) ? superclass.attribute_by_columns : {}
      (@attribute_by_columns || {}).merge(derived)
    end

    def validates_db_uniqueness
      derived = superclass.respond_to?(:validates_db_uniqueness) ? superclass.validates_db_uniqueness : []
      (@validates_db_uniqueness || []) + derived
    end
  end
end
