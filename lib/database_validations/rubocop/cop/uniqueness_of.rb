module RuboCop
  module Cop
    module DatabaseValidations
      # Use `validates_db_uniqueness_of` for uniqueness validation.
      #
      # @example
      #   # bad
      #   validates :slug, uniqueness: true
      #   validates :address, uniqueness: { scope: :user_id }
      #   validates_uniqueness_of :title
      #
      #   # good
      #   validates_db_uniqueness_of :slug
      #   validates_db_uniqueness_of :address, scope: :user_id
      #   validates_db_uniqueness_of :title
      #
      class UniquenessOf < Cop
        MSG = 'Use `validates_db_uniqueness_of`.'.freeze

        def_node_matcher :uniquness_validation?, '(pair (sym :uniqueness) _)'

        def on_send(node)
          if node.method_name == :validates_uniqueness_of
            add_offense(node, location: :selector)
          elsif node.method_name == :validates
            uniqueness(node) do |option|
              add_offense(option)
            end
          end
        end

        private

        def uniqueness(node)
          options = node.last_argument
          return unless options.hash_type?

          options.each_child_node(:pair) do |pair|
            yield pair if uniquness_validation?(pair)
          end
        end
      end
    end
  end
end
