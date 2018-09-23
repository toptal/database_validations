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
      error_options = options.except(:case_sensitive, :scope, :conditions, :attributes, :where)
      error_options[:value] = instance.public_send(options[:attributes])

      instance.errors.add(options[:attributes], :taken, error_options)
    end

    def validates_uniqueness_options
      where_clause_str = where_clause

      options.except(:where)
        .merge(allow_nil: true, case_sensitive: true, allow_blank: false)
        .tap { |opts| opts[:conditions] = -> { where(where_clause_str) } if where_clause }
    end

    def if_and_unless_pass?(instance)
      (options[:if].nil? || condition_passes?(options[:if], instance)) &&
        (options[:unless].nil? || !condition_passes?(options[:unless], instance))
    end

    def key
      @key ||= Helpers.generate_key(columns)
    end

    def columns
      @columns ||= Helpers.unify_columns(field, Array.wrap(options[:scope]))
    end

    def where_clause
      @where_clause ||= options[:where]
    end

    private

    attr_reader :adapter, :field, :options

    def condition_passes?(condition, instance)
      if condition.is_a?(Symbol)
        instance.__send__(condition)
      elsif condition.is_a?(Proc) && condition.arity == 0
        instance.instance_exec(&condition)
      else
        instance.instance_eval(&condition)
      end
    end

    def raise_if_unsupported_options!
      options.except(:attributes).each_key do |option|
        unless adapter.support_option?(option)
          raise Errors::OptionIsNotSupported.new(option, adapter.adapter_name, adapter.supported_options)
        end
      end
    end

    def raise_if_index_missed!
      raise Errors::IndexNotFound.new(columns, where_clause, adapter.indexes) unless adapter.find_index(columns, where_clause)
    end
  end
end

