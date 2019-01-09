module RuboCop
  module Cop
    module DatabaseValidations
      # Use `db_belongs`_to instead of `belongs_to`.
      #
      # @example
      #   # bad
      #   belongs_to :company
      #
      #   # good
      #   db_belongs_to :company
      #
      class BelongsTo < Cop
        MSG = 'Use `db_belongs_to`.'.freeze

        NON_SUPPORTED_OPTIONS = %i[
          optional
          required
          polymorphic
          foreign_type
        ].freeze

        def_node_matcher :belongs_to?, '(send nil? :belongs_to ...)'
        def_node_matcher :option_name, '(pair (sym $_) ...)'

        def on_send(node)
          return unless belongs_to?(node)
          return unless supported?(node)

          add_offense(node, location: :selector)
        end

        private

        def supported?(node)
          options = node.arguments.last
          return true unless options.hash_type?

          options.each_child_node.none? do |option|
            NON_SUPPORTED_OPTIONS.include? option_name(option)
          end
        end
      end
    end
  end
end
