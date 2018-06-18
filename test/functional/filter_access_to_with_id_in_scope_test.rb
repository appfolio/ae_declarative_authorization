require 'test_helper'

class UsersController < MocksController
  before_action :initialize_user
  filter_access_to :all, attribute_check: true
  define_action_methods :show

  def initialize_user
    @user = User.find(params[:id])
  end
end

class FilterAccessToWithIdInScopeTest < ActionController::TestCase
  include DeclarativeAuthorization::Test::Helpers

  tests UsersController

  access_tests do
    params :user do |old_user, new_user|
      assert_equal :old_user, old_user
      assert_equal :new_user, new_user
      { id: User.create! }
    end
    
    role :users do
      privilege :read do
        allowed to: :show, with: :user
      end
    end
  end

  AUTHORIZATION_RULES = <<-RULES.freeze
    authorization do
      role :users__read do
        has_permission_on :users, :to => [:show] do
          if_attribute :id => id_in_scope { User.visible_by(user) }
        end
      end
    end
  RULES

  setup do
    @reader = Authorization::Reader::DSLReader.new
    @reader.parse(AUTHORIZATION_RULES)
    Authorization::Engine.instance(@reader)
  end

  def test_id_in_scope__filter_access_to__has_access
    with_routing do |map|
      setup_routes(map)

      current_user = User.create!(role_symbols: [:users__read])
      different_user = User.create!

      request!(current_user, :show, @reader, id: current_user.id)
      assert @controller.authorized?
    end
  end

  def test_id_in_scope__filter_access_to__does_not_have_access
    with_routing do |map|
      setup_routes(map)

      current_user = User.create!(role_symbols: [:users__read])
      different_user = User.create!

      request!(current_user, :show, @reader, id: different_user.id)
      assert !@controller.authorized?
    end
  end

  private

  def setup_routes(map)
    map.draw do
      get '/users', controller: 'users', action: :show
    end
  end

  def access_test_user(role, privilege)
    User.new(role_symbols: [ :"#{role}__#{privilege}" ])
  end

  def access_test_params_for_param_methods
    [:old_user, :new_user]
  end
end

