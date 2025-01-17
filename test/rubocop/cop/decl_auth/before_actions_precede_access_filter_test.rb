# frozen_string_literal: true

require 'test_helper'
require 'rubocop'
require 'rubocop/cop/decl_auth/before_actions_precede_access_filter'

# rubocop:disable Metrics/ MethodLength
module Rubocop
  module Cop
    module DeclAuth
      class BeforeActionsPrecedeAccessFilterTest < Minitest::Test
        def setup
          config = RuboCop::Config.new(
            { RuboCop::Cop::DeclAuth::BeforeActionsPrecedeAccessFilter.badge.to_s => {} },
            '/'
          )
          @cop = RuboCop::Cop::DeclAuth::BeforeActionsPrecedeAccessFilter.new(config)
          @commissioner = RuboCop::Cop::Commissioner.new([@cop], [])
        end

        def test_offense_when_access_filter_precedes_any_before_action
          source = <<-SOURCE
            module TestModule
              class TestController
                before_action :asdf
                filter_access_to :all
                before_action :qwerty
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 1, offenses.size
          assert_equal 'filter_access_to :all', offenses.first.location.source
        end

        def test_no_offense_when_all_before_actions_precede_access_filter
          source = <<-SOURCE
            module TestModule
              class TestController
                before_action :asdf
                before_action :qwerty
                filter_access_to :all
              end
            end
          SOURCE

          offenses = analyze_source(source)

          assert_equal 0, offenses.size
        end

        def test_no_offense_when_no_before_actions
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

