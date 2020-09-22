module DatabaseValidations
  class DbPresenceValidator < ActiveRecord::Validations::PresenceValidator
    REFLECTION_MESSAGE = ActiveRecord::VERSION::MAJOR < 5 ? :blank : :required

    attr_reader :klass

    # Used to make 3rd party libraries work correctly
    #
    # @return [Symbol]
    def self.kind
      :presence
    end

    # @param [Hash] options
    def initialize(options)
      @klass = options[:class]

      super

      Injector.inject(klass)
      Checkers::DbPresenceValidator.validate!(self)
    end

    def perform_db_validation?
      true
    end

    # TODO: add support of optional db_belongs_to
    def validate(record)
      if record._database_validations_fallback
        super
      else
        attributes.each do |attribute|
          reflection = record.class._reflect_on_association(attribute)

          next if reflection && record.public_send(reflection.foreign_key).present?

          validate_each(record, attribute, record.public_send(attribute))
        end
      end
    end

    def apply_error(instance, attribute)
      # Helps to avoid querying the database when attribute is association
      instance.send("#{attribute}=", nil)
      instance.errors.add(attribute, :blank, message: REFLECTION_MESSAGE)
    end
  end

  module ClassMethods
    def validates_db_presence_of(*attr_names)
      validates_with(DatabaseValidations::DbPresenceValidator, _merge_attributes(attr_names))
    end

    def db_belongs_to(name, scope = nil, **options)
      if ActiveRecord::VERSION::MAJOR < 5
        options[:required] = false
      else
        options[:optional] = true
      end

      belongs_to(name, scope, **options)

      validates_with DatabaseValidations::DbPresenceValidator, _merge_attributes([name, message: DatabaseValidations::DbPresenceValidator::REFLECTION_MESSAGE]) # rubocop:disable Metrics/LineLength
    end
  end
end
