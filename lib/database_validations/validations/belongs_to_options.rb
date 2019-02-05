module DatabaseValidations
  class BelongsToOptions
    attr_reader :column, :adapter, :relation

    def initialize(column, relation, adapter)
      @column = column
      @relation = relation
      @adapter = adapter

      raise_if_unsupported_database!
      raise_if_foreign_key_missed! unless ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK']
    end

    # @return [String]
    def key
      Helpers.generate_key_for_belongs_to(column)
    end

    # @return [Boolean]
    def column_and_relation_nil_for?(instance)
      instance.public_send(column).nil? && instance.public_send(relation).nil?
    end

    def handle_foreign_key_error(instance)
      # Hack to not query the database because we know the result already
      instance.send("#{relation}=", nil)
      instance.errors.add(relation, :blank, message: :required)
    end

    def validates_presence_options
      { attributes: relation, message: :required }
    end

    private

    def raise_if_foreign_key_missed!
      raise Errors::ForeignKeyNotFound.new(column, adapter.foreign_keys) unless adapter.find_foreign_key_by_column(column)
    end

    def raise_if_unsupported_database!
      raise Errors::UnsupportedDatabase.new(:db_belongs_to, adapter.adapter_name) if adapter.adapter_name == :sqlite3
    end
  end
end
