require 'test_helper'

class ParamsBlockArityTest < ActionController::TestCase
  include DeclarativeAuthorization::Test::Helpers

  class ParamsBlockArityTestController < ApplicationController

  end

  tests ParamsBlockArityTestController

  access_tests do

    params :less_than_max_arguments do | one |
      { this: :works }
    end

    params :too_many_arguments do | one, two, three |
      { what: :ever }
    end

  end

  def test_params_arity
    assert_raises(InvalidParamsBlockArity) do
      access_test_params(:too_many_arguments)
    end

    assert_equal({ this: :works }, access_test_params(:less_than_max_arguments))
  end

  private

  def access_test_params_for_param_methods
    [:old_user, :new_user]
  end

end

