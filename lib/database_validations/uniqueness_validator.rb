# First approach exactly for ActiveRecord

module DatabaseValidations
  module UniquenessValidator

    def save(*args, &block)
      super
    rescue ActiveRecord::RecordNotUnique
      errors.add(:token_id, :taken, value: token_id)
      false
    end

    def save!(*args, &block)
      super
    rescue ActiveRecord::RecordNotUnique
      errors.add(:token_id, :taken, value: token_id)
      raise ActiveRecord::RecordInvalid, self
    end

    def valid?
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

    check_unique_index!(attributes + scope)

    prepend(Module.new do

      define_method :save do |*a, &b|
        super(*a, &b)
      rescue ActiveRecord::RecordNotUnique
        errors.add(attributes.first, :taken, value: public_send(attributes.first))
        false
      end

      define_method :save! do |*a, &b|
        super(*a, &b)
      rescue ActiveRecord::RecordNotUnique
        errors.add(attributes.first, :taken, value: public_send(attributes.first))
        raise ActiveRecord::RecordInvalid, self
      end

      # This is not fine because then it will be triggered before each save/save!
      # So we need to know when we directly asked about valid? or through save/save!
      # define_method :valid? do |*a, &b|
      #   validates_with ActiveRecord::Validations::UniquenessValidator, options.merge(attributes: Array.wrap(args))
      #   super(*a, &b)
      # end
    end)
  end

  private

  def check_unique_index!(columns)
    index = connection.indexes(table_name).select(&:unique).find { |index| index.columns.map(&:to_s).sort == columns.map(&:to_s).sort }
    raise Errors::IndexNotFound.new(columns) unless index
  end
end
