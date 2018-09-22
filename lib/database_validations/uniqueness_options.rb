module DatabaseValidations
  class UniquenessOptions
    def initialize(field, options, adapter)
      @field = field
      @options = options
      @adapter = adapter

      raise_if_unsupported_options!
      raise_if_index_missed! unless ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']
    end

    def handle_unique_error(instance)
      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end

    def validates_uniqueness_options
      options.merge(allow_nil: true, case_sensitive: true, allow_blank: false)
    end

    def key
      @key ||= Helpers.generate_key(columns)
    end

    def columns
      @columns ||= Helpers.unify_columns(field, Array.wrap(options[:scope]))
    end

    def raise_if_unsupported_options!
      options.except(:attributes).each_key do |option|
        unless adapter.support_option?(option)
          raise Errors::OptionIsNotSupported.new(option, adapter.adapter_name, adapter.supported_options)
        end
      end
    end

    def raise_if_index_missed!
      raise Errors::IndexNotFound.new(columns) unless adapter.find_index_by_columns(columns)
    end

    private

    attr_reader :adapter, :field, :options
  end
end

