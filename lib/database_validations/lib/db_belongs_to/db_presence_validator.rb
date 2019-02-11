module DatabaseValidations
  class DBPresenceValidator < ActiveRecord::Validations::PresenceValidator
    # This is a hack to simulate presence validator
    # It's used for cases when some 3rd parties are relies on the validators
    # For example, +required+ option from simple_form checks the validator
    def self.kind
      :presence
    end

    attr_reader :foreign_key, :association

    def initialize(options)
      super(options)

      @association = attributes.first
      @foreign_key = options[:foreign_key]
    end

    # The else statement required only for optional: false
    def validate(record)
      if record._database_validations_fallback
        super
      else
        return unless record.public_send(foreign_key).blank? && record.public_send(association).blank?

        record.errors.add(association, :blank, message: :required)
      end
    end
  end
end
