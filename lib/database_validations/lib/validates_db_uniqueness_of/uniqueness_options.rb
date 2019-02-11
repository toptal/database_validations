module DatabaseValidations
  class UniquenessOptions
    CUSTOM_OPTIONS = %i[where index_name].freeze
    DEFAULT_OPTIONS = { allow_nil: true, case_sensitive: true, allow_blank: false }.freeze

    def self.validator_options(attributes, options)
      DEFAULT_OPTIONS.merge(attributes: attributes)
        .merge(options)
        .except(*CUSTOM_OPTIONS)
        .tap { |opts| opts[:conditions] = -> { where(options[:where]) } if options[:where] }
    end

    attr_reader :field

    def initialize(field, options, adapter)
      @field = field
      @options = options
      @adapter = adapter

      raise_if_unsupported_options!
      raise_if_index_missed! unless ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']
    end

    def handle_unique_error(instance)
      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes, *CUSTOM_OPTIONS)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end

    # @return [String]
    def key
      @key ||= index_name ? Helpers.generate_key_for_uniqueness_index(index_name) : Helpers.generate_key_for_uniqueness(columns)
    end

    # @return [Array<String>]
    def columns
      @columns ||= Helpers.unify_columns(field, scope)
    end

    # @return [String|nil]
    def where_clause
      @where_clause ||= options[:where]
    end

    # @return [String|nil]
    def message
      @message ||= options[:message]
    end

    # @return [Array<String|Symbol>]
    def scope
      @scope ||= Array.wrap(options[:scope])
    end

    # @return [String|Symbol|nil]
    def index_name
      @index_name ||= options[:index_name]
    end

    # @return [Boolean|nil]
    def case_sensitive
      @case_sensitive ||= options[:case_sensitive]
    end

    private

    attr_reader :adapter, :options

    def raise_if_unsupported_options!
      options.except(:attributes).each_key do |option|
        unless adapter.support_option?(option)
          raise Errors::OptionIsNotSupported.new(option, adapter.adapter_name, adapter.supported_options)
        end
      end
    end

    def raise_if_index_missed! # rubocop:disable Metrics/AbcSize
      unless (index_name && adapter.find_index_by_name(index_name.to_s)) ||
             (!index_name && adapter.find_index(columns, where_clause))
        raise Errors::IndexNotFound.new(columns, where_clause, index_name, adapter.indexes, adapter.table_name)
      end
    end
  end
end
