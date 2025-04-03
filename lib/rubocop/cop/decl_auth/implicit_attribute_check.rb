# frozen_string_literal: true

module RuboCop
  module Cop
    module DeclAuth
      # Enforces placing all `before_action` statements prior to the first `filter_access_to` statement.
      # This ensures that any data required by the access filters is available before the filter is applied.
      # See the documentation above the `filter_access_to` method in Authorization::Controller::DSL for more information
      #
      # @example
      #   # bad
      #   filter_access_to :all, attribute_check: true
      #
      #   before_action :find_object
      #   before_action: :do_something
      #
      #   # good
      #   before_action :find_object
      #   filter_access_to :all, attribute_check: true
      #
      #   before_action: :do_something
      #
      #   # good
      #   filter_access_to :all, attribute_check: true, load_method: :find_object
      class ImplicitAttributeCheck < RuboCop::Cop::Base
        def_node_search :before_actions, '(send nil? :before_action ...)'
        def_node_search :attribute_check_filters, <<-PATTERN
          (send nil? :filter_access_to
            ...
            (hash
              <(pair (sym :attribute_check) true)...>
            )
            ...
          )
        PATTERN

        MSG = <<-MSG
`filter_access_to` statements with `attribute_check` enabled and no `load_method`
should often have at least one `before_action` above it. There are exceptions to this rule,
in which case you can add `# rubocop:disable DeclAuth/ImplicitAttributeCheck` to the line.`
        MSG

        def on_class(node)
          before_actions = before_actions(node)
          attribute_check_filters = attribute_check_filters(node)

          # find access filters that have attribute_check enabled but do not supply a load method
          naked_attr_check_filters = attribute_check_filters.select do |filter|
            hash_arg = filter.arguments.find { |arg| arg.hash_type? }
            next unless hash_arg

            hash_arg.keys.none? { |key| key.value == :load_method }
          end

          return if naked_attr_check_filters.count.zero?

          # Add offenses if there are naked attribute check filters that precede the first before_action

          first_naked_filter = naked_attr_check_filters.to_a.first
          if before_actions.count.zero?
            add_offense(first_naked_filter, message: MSG)
            return
          end

          first_before_action = before_actions.to_a.first
          return if first_before_action.sibling_index < first_naked_filter.sibling_index

          add_offense(first_naked_filter, message: MSG)
        end
      end
    end
  end
end
