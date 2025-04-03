# frozen_string_literal: true

require 'test_helper'
require 'rubocop'
require 'rubocop/cop/decl_auth/implicit_attribute_check'

# rubocop:disable Metrics/ MethodLength
module Rubocop
  module Cop
    module DeclAuth
      # FIXME: this should only affect if the filter_access_to has attribute_check: true
      #  no load_method supplied, and no before actions before it. Even then, it should still
      #  be a warning, because rails magic might supply the object automatically.
      class ImplicitAttributeCheckTest < Minitest::Test
        def setup
          config = RuboCop::Config.new(
            { RuboCop::Cop::DeclAuth::ImplicitAttributeCheck.badge.to_s => {} },
            '/'
          )
          @cop = RuboCop::Cop::DeclAuth::ImplicitAttributeCheck.new(config)
          @commissioner = RuboCop::Cop::Commissioner.new([@cop], [])
        end

        def test_offense_when_access_filter_with_attribute_check__no_load_method_or_preceding_before_actions
          source = <<-SOURCE
            module TestModule
              class TestController
                filter_access_to :all, attribute_check: true

                before_action :asdf
                before_action :qwerty
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 1, offenses.size
          assert_equal 'filter_access_to :all, attribute_check: true', offenses.first.location.source
        end

        def test_offense_when_access_filter_with_attribute_check__no_load_method_no_before_actions
          source = <<-SOURCE
            module TestModule
              class TestController
                filter_access_to :all, attribute_check: true
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 1, offenses.size
          assert_equal 'filter_access_to :all, attribute_check: true', offenses.first.location.source
        end

        def test_offense__multiple_access_filters
          source = <<-SOURCE
            module TestModule
              class TestController
                filter_access_to :action_zero
                filter_access_to :action_one, requires: :update
                filter_access_to :action_two, attribute_check: true, load_method: :load_user
                filter_access_to :action_three, attribute_check: true
                filter_access_to :action_four, :action_five, attribute_check: true
                filter_access_to :action_six, context: :blah, attribute_check: true

                before_action :asdf
                before_action :qwerty
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 1, offenses.size
          assert_equal 'filter_access_to :action_three, attribute_check: true', offenses[0].location.source
        end

        def test_no_offense_when_at_least_one_before_action_precedes_access_filter
          source = <<-SOURCE
            module TestModule
              class TestController
                before_action :asdf

                filter_access_to :all, attribute_check: true

                before_action :qwerty
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 0, offenses.size
        end

        def test_no_offense_when_no_attribute_check
          source = <<-SOURCE
            module TestModule
              class TestController
                filter_access_to :all
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 0, offenses.size
        end

        def test_no_offense_when_load_method_supplied
          source = <<-SOURCE
            module TestModule
              class TestController
                filter_access_to :all, attribute_check: true, load_method: :load_user
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 0, offenses.size
        end

        def test_no_offense_when_no_access_filters
          source = <<-SOURCE
            module TestModule
              class TestController
                before_action :asdf
                before_action :qwerty
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 0, offenses.size
        end

        private

        def analyze_source(source)
          @commissioner.investigate(@cop.parse(source)).offenses
        end

      end
    end
  end
end

