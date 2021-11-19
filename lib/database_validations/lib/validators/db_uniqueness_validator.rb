module DatabaseValidations
  class DbUniquenessValidator < ActiveRecord::Validations::UniquenessValidator
    DEFAULT_MODE = :optimized

    attr_reader :index_name, :where, :klass

    # Used to make 3rd party libraries work correctly
    #
    # @return [Symbol]
    def self.kind
      :uniqueness
    end

    # @param [Hash] options
    def initialize(options)
      options[:allow_nil] = true
      options[:allow_blank] = false

      if options.key?(:where)
        condition = options[:where]
        options[:conditions] = -> { where(condition) }
      end

      handle_custom_options(options)

      super

      Injector.inject(klass)
      Checkers::DbUniquenessValidator.validate!(self)
    end

    def perform_rescue?(validate)
      (validate != false && @mode != :standard) || @rescue == :always
    end

    def validate(record)
      super if perform_query? || record._database_validations_fallback
    end

    def apply_error(instance, attribute)
      error_options = options.except(:case_sensitive, :scope, :conditions)
      error_options[:value] = instance.public_send(attribute)

      instance.errors.add(attribute, :taken, **error_options)
    end

    private

    def handle_custom_options(options)
      @index_name = options.delete(:index_name) if options.key?(:index_name)
      @where = options.delete(:where) if options.key?(:where)
      @mode = (options.delete(:mode).presence || DEFAULT_MODE).to_sym
      @rescue = (options.delete(:rescue).presence || :default).to_sym
    end

    def perform_query?
      @mode != :optimized
    end
  end

  module ClassMethods
    def validates_db_uniqueness_of(*attr_names)
      validates_with(DatabaseValidations::DbUniquenessValidator, _merge_attributes(attr_names))
    end
  end
end
