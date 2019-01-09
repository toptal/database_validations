module RuboCop
  module Cop
    module DatabaseValidations
      # Use `validates_db_uniqueness_of` for uniqueness validation.
      #
      # @example
      #   # bad
      #   validates :slug, uniqueness: true
      #   validates :address, uniqueness: { scope: :user_id }
      #
      #   # good
      #   validates_db_uniqueness_of :slug
      #   validates_db_uniqueness_of :address, scope: :user_id
      #
      class UniquenessOf < Cop
        MSG = 'Use `validates_db_uniqueness_of`.'.freeze

        def_node_matcher :uniquness_validation?, '(pair (sym :uniqueness) $_)'

        def on_send(node)
          return unless node.method_name == :validates

          uniqueness(node) do |option|
            add_offense(option)
          end
        end

        private

        def uniqueness(node)
          options = node.arguments.last
          return unless options.hash_type?

          options.each_child_node do |child|
            yield child if uniquness_validation?(child)
          end
        end
      end
    end
  end
end
