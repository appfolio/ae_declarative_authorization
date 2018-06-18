require 'test_helper'

class NoFilterAccessObject < MockDataObject
  def self.name
    "NoFilterAccessObject"
  end
end

class NoFilterAccessObjectsController < MocksController
  filter_access_to :all, attribute_check: true, load_method: :find_no_filter_access_object
  no_filter_access_to :index

  define_action_methods :index, :show

  private

  def find_no_filter_access_object
    NoFilterAccessObject.find_or_initialize_by(params.permit(:id, :special_attribute).to_hash)
  end
end

class NoFilterAccessToTest < ActionController::TestCase
  include DeclarativeAuthorization::Test::Helpers
  tests NoFilterAccessObjectsController

  access_tests_not_required

  AUTHORIZATION_RULES = <<-RULES.freeze
    authorization do
      role :allowed_role do
        has_permission_on :no_filter_access_objects, to: :index do
          if_attribute special_attribute: is { 'secret' }
        end
        has_permission_on :no_filter_access_objects, to: :show do
          if_attribute id: is { '1' }
        end
      end
    end
  RULES

  setup do
    @reader = Authorization::Reader::DSLReader.new
    @reader.parse(AUTHORIZATION_RULES)
    Authorization::Engine.instance(@reader)
  end

  def test_filter_access_to
    with_routing do |map|
      map.draw do
        resources :no_filter_access_objects, only: [:index, :show]
      end

      disallowed_user = MockUser.new
      allowed_user = MockUser.new(:allowed_role)

      request!(disallowed_user, :show, @reader, id: '1')
      assert !@controller.authorized?

      request!(allowed_user, :show, @reader, id: '100', clear: [:@no_filter_access_object])
      assert !@controller.authorized?

      request!(allowed_user, :show, @reader, id: '1', clear: [:@no_filter_access_object])
      assert @controller.authorized?
    end
  end

  def test_no_filter_access_to
    with_routing do |map|
      map.draw do
        resources :no_filter_access_objects, only: [:index, :show]
      end

      non_special_user = MockUser.new

      request!(non_special_user, :index, @reader, id: '1', special_attribute: 'wrong')
      assert @controller.authorized?
    end
  end
end
