module DatabaseValidations
  module Adapters
    class BaseAdapter
      attr_reader :model

      def initialize(model)
        @model = model
      end
    end
  end
end
