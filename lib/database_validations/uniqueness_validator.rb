module DatabaseValidations
  module UniquenessValidator
    def save(*a, &b)
      super(*a, &b)
    rescue ActiveRecord::RecordNotUnique => e
      DatabaseValidations::Helpers.handle_unique_error(self, e)
      false
    end

    def save!(*a, &b)
      super(*a, &b)
    rescue ActiveRecord::RecordNotUnique => e
      DatabaseValidations::Helpers.handle_unique_error(self, e)
      raise ActiveRecord::RecordInvalid, self
    end
  end

  def validates_db_uniqueness_of(*attributes)
    options = attributes.extract_options!

    validates_db_uniqueness.concat(attributes.map do |field|
      columns = [field, Array.wrap(options[:scope])].flatten!.map!(&:to_s).sort!

      DatabaseValidations::Helpers.check_unique_index!(self, columns)

      options.merge(field: field, columns: columns)
    end)

    prepend(UniquenessValidator)
  end

  def validates_db_uniqueness
    @validates_db_uniqueness_of ||= []
  end
end
