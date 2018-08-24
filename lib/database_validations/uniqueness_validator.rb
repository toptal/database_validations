# First approach exactly for ActiveRecord

module DatabaseValidations
  module UniquenessValidator
    def save(*a, &b)
      super(*a, &b)
    rescue ActiveRecord::RecordNotUnique => e
      columns = DatabaseValidations::Adapters.factory(self.class).columns(e.message)
      field = DatabaseValidations::Helpers.field(self.class, columns)
      errors.add(field, :taken, value: public_send(field))
      false
    end

    def save!(*a, &b)
      super(*a, &b)
    rescue ActiveRecord::RecordNotUnique => e
      columns = DatabaseValidations::Adapters.factory(self.class).columns(e.message)
      field = DatabaseValidations::Helpers.field(self.class, columns)
      errors.add(field, :taken, value: public_send(field))
      raise ActiveRecord::RecordInvalid, self
    end
  end

  # What should do:
  # - Check on boot time that index exists
  # - Check validity of validator
  # - Add validation to a model

  # Configuration options:
  #
  # * <tt>:message</tt> - Specifies a custom error message (default is:
  #   "has already been taken").
  # * <tt>:scope</tt> - One or more columns by which to limit the scope of
  #   the uniqueness constraint.
  # * <tt>:conditions</tt> - Specify the conditions to be included as a
  #   <tt>WHERE</tt> SQL fragment to limit the uniqueness constraint lookup
  #   (e.g. <tt>conditions: -> { where(status: 'active') }</tt>).
  # * <tt>:case_sensitive</tt> - Looks for an exact match. Ignored by
  #   non-text columns (+true+ by default).
  # * <tt>:allow_nil</tt> - If set to +true+, skips this validation if the
  #   attribute is +nil+ (default is +false+).
  # * <tt>:allow_blank</tt> - If set to +true+, skips this validation if the
  #   attribute is blank (default is +false+).
  # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
  #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
  #   proc or string should return or evaluate to a +true+ or +false+ value.
  # * <tt>:unless</tt> - Specifies a method, proc or string to call to
  #   determine if the validation should not occur (e.g. <tt>unless: :skip_validation</tt>,
  #   or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). The
  #   method, proc or string should return or evaluate to a +true+ or +false+
  #   value.
  #
  # validates_db_uniqueness_of :field_1, :field_2, conditions: -> {}, scope: [:scope], case_sensitive: false,

  def validates_db_uniqueness_of(*attributes)
    options = attributes.extract_options!
    scope = Array.wrap(options[:scope])

    validates_db_uniqueness.concat attributes.map { |field| options.merge(field: field, columns: [field, scope].flatten.map!(&:to_s).sort!) }

    DatabaseValidations::Helpers.check_unique_index!(self, attributes, scope)

    prepend(UniquenessValidator)
  end

  def validates_db_uniqueness
    @validates_db_uniqueness_of ||= []
  end
end
