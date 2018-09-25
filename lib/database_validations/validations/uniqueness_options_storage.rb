module DatabaseValidations
  class UniquenessOptionsStorage

    def initialize(klass)
      @adapter = Adapters.factory(klass)
      @storage = {}
    end

    def push(field, options)
      uniqueness_options = UniquenessOptions.new(field, options, adapter)
      storage[uniqueness_options.key] = uniqueness_options
    end

    def [](key)
      storage[key]
    end

    def each_validator
      storage.each_value { |validator| yield(validator) }
    end

    private

    attr_reader :storage, :adapter
  end
end
