module DatabaseValidations
  module Adapters
    class BaseAdapter
      attr_reader :model

      def initialize(model)
        @model = model
      end

      def index_columns(index_name)
        model.connection
          .indexes(model.table_name)
          .find { |index| index.name == index_name  }
          .columns
      end
    end
  end
end
