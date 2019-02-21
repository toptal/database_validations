module DatabaseValidations
  class UniquenessOptions
    CUSTOM_OPTIONS = %i[where index_name].freeze
    DEFAULT_OPTIONS = { allow_nil: true, case_sensitive: true, allow_blank: false }.freeze

    def self.validator_options(attributes, options)
      DEFAULT_OPTIONS
        .merge(attributes: attributes)
        .merge(options)
        .except(*CUSTOM_OPTIONS)
        .tap { |opts| opts[:conditions] = -> { where(options[:where]) } if options[:where] }
    end

    attr_reader :field, :calculated_index_name

    def initialize(field, options, adapter)
      @field = field
      @options = options
      @adapter = adapter

      raise_if_unsupported_options!

      return if ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']

      index = responsible_index
      raise_if_index_missed!(index)

      @calculated_index_name = index.name
    end

    def handle_unique_error(instance)
      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes, *CUSTOM_OPTIONS)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end

    # @return [String]
    def index_key
      @index_key ||= Helpers.generate_key_for_uniqueness_index(index_name || calculated_index_name)
    end

    # @return [String]
    def column_key
      @column_key ||= Helpers.generate_key_for_uniqueness(columns)
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

    def responsible_index
      index_name ? adapter.find_index_by_name(index_name.to_s) : adapter.find_index(columns, where_clause)
    end

    def index_columns_size(columns)
      columns.is_a?(Array) ? columns.size : (columns.count(',') + 1)
    end

    def check_index_options?(index)
      (columns.size == index_columns_size(index.columns)) && (where_clause.nil? == index.where.nil?)
    end

    def raise_if_index_missed!(index)
      return if index && check_index_options?(index)

      raise Errors::IndexNotFound.new(columns, where_clause, index_name, adapter.indexes, adapter.table_name)
    end
  end
end
