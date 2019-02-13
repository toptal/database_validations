module DatabaseValidations
  module ClassMethods
    def db_belongs_to(name, scope = nil, **options)
      Helpers.cache_valid_method!(self)

      @database_validations_storage ||= DatabaseValidations::OptionsStorage.new(self)

      belongs_to(name, scope, options.merge(optional: true))

      foreign_key = reflections[name.to_s].foreign_key

      @database_validations_storage.push_belongs_to(foreign_key, name)

      validates_with DatabaseValidations::DBPresenceValidator,
                     DatabaseValidations::BelongsToOptions.validator_options(name, foreign_key)

      include(DatabaseValidations::Rescuer)
    end
  end
end
