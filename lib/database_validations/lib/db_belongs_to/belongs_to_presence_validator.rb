module DatabaseValidations
  module Validations
    class BelongsToPresenceValidator < ActiveModel::Validator
      attr_reader :attributes

      # This is a hack to simulate presence validator
      # It's used for cases when some 3rd parties are relies on the validators
      # For example, required option from simple_form checks the validator
      def self.kind
        :presence
      end

      def initialize(options = {})
        @attributes = [options[:relation]]
        super
      end

      def validate(record)
        return unless record.public_send(options[:column]).blank? && record.public_send(options[:relation]).blank?

        record.errors.add(options[:relation], :blank, message: :required)
      end
    end
  end
end
