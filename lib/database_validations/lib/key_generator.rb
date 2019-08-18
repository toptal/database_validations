module DatabaseValidations
  module KeyGenerator
    module_function

    # @param [String] index_name
    #
    # @return [String]
    def for_unique_index(index_name)
      generate_key(:unique_index, index_name)
    end

    # @return [String]
    def for_db_uniqueness(*columns)
      generate_key(:db_uniqueness, columns)
    end

    # @return [String]
    def for_db_presence(column)
      generate_key(:db_presence, column)
    end

    # @return [String]
    def generate_key(type, *args)
      [type, *unify_columns(args)].join('__')
    end

    # @return [String]
    def unify_columns(*args)
      args.flatten.compact.map(&:to_s).sort
    end
  end
end
