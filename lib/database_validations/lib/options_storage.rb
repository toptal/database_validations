module DatabaseValidations
  class OptionsStorage
    def initialize(klass)
      @adapter = Adapters.factory(klass).new(klass)
      @storage = {}
    end

    def push_uniqueness(field, options)
      uniqueness_options = UniquenessOptions.new(field, options, adapter)
      storage[uniqueness_options.index_key] = uniqueness_options
      storage[uniqueness_options.column_key] = uniqueness_options
    end

    def push_belongs_to(field, relation)
      belongs_to_options = BelongsToOptions.new(field, relation, adapter)
      storage[belongs_to_options.key] = belongs_to_options
    end

    def [](key)
      storage[key]
    end

    def options
      storage.values
    end

    private

    attr_reader :storage, :adapter
  end
end
