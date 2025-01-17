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
      #   before_action: :do_something
      #   filter_access_to :all
      #   before_action :find_object
      #
      #   # good
      #   before_action: :do_something
      #   before_action :find_object
      #
      #   filter_access_to :all
      #
      class BeforeActionsPrecedeAccessFilter < RuboCop::Cop::Base
        def_node_search :before_actions, '(send nil? :before_action ...)'
        def_node_search :access_filters, '(send nil? :filter_access_to ...)'

        MSG = '`:filter_access_to` statements should be placed after all other `:before_action` statements.'

        def on_class(node)
          before_actions = before_actions(node)
          access_filters = access_filters(node)

          return if before_actions.count.zero? || access_filters.count.zero?

          last_before_action = before_actions.to_a.last
          first_access_filter = access_filters.to_a.first

          return if last_before_action.sibling_index < first_access_filter.sibling_index

          add_offense(access_filters.first, message: MSG)
        end
      end
    end
  end
end
