module DatabaseValidations
  class OptionsStorage
    def initialize(klass)
      @adapter = Adapters.factory(klass)
      @storage = {}
    end

    def push_uniqueness(field, options)
      uniqueness_options = UniquenessOptions.new(field, options, adapter)
      storage[uniqueness_options.index_key] = uniqueness_options
      storage[uniqueness_options.column_key] = uniqueness_options
    end

    def push_belongs_to(field, relation)
      belongs_to_options = BelongsToOptions.new(field, relation, adapter)
      storage[belongs_to_options.index_key] = belongs_to_options
      storage[belongs_to_options.column_key] = belongs_to_options
    end

    def [](key)
      storage[key]
    end

    def each_uniqueness_validator
      storage.values.grep(UniquenessOptions).each { |validator| yield(validator) }
    end

    def each_belongs_to_presence_validator
      storage.values.grep(BelongsToOptions).each { |validator| yield(validator) }
    end

    private

    attr_reader :storage, :adapter
  end
end
