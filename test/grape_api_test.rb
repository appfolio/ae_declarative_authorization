require 'test_helper'

# TODO: remove this conditional when rails 4 support is removed
if defined?(Grape)
  class LoadMockObject < MockDataObject
    def self.name
      "LoadMockObject"
    end
  end

  ##################
  class SpecificMocks < MocksAPI
    filter_access_to 'GET /specific_mocks/test_action', :require => :test, :context => :permissions
    filter_access_to 'GET /specific_mocks/test_action_2', :require => :test, :context => :permissions_2
    filter_access_to 'GET /specific_mocks/show'
    filter_access_to 'GET /specific_mocks/edit', 'POST /specific_mocks/create', :require => :test, :context => :permissions
    filter_access_to 'GET /specific_mocks/edit2', :require => :test, :context => :permissions,
      :attribute_check => true, :model => LoadMockObject
    filter_access_to 'GET /specific_mocks/new', :require => :test, :context => :permissions

    filter_access_to ['GET /specific_mocks/action_group_action_1', 'GET /specific_mocks/action_group_action_2']
    define_action_methods :test_action, :test_action_2, :show, :edit, :create,
      :edit_2, :new, :unprotected_action, :action_group_action_1, :action_group_action_2
  end

  class BasicAPITest < ApiTestCase
    tests SpecificMocks

    def test_method_not_allowed
      reader = Authorization::Reader::DSLReader.new
      request!(MockUser.new(:test_role), "/specific_mocks/test_action", reader, method: :delete)
      assert_equal 405, last_response.status
    end

    def test_filter_access_to_receiving_an_explicit_array
      reader = Authorization::Reader::DSLReader.new

      reader.parse %{
        authorization do
          role :test_action_group_2 do
            has_permission_on :specific_mocks, :to => 'GET /specific_mocks/action_group_action_2'
          end
        end
      }

      request!(MockUser.new(:test_action_group_2), "/specific_mocks/action_group_action_2", reader)
      assert last_endpoint.authorized?
      request!(MockUser.new(:test_action_group_2), "/specific_mocks/action_group_action_1", reader)
      assert !last_endpoint.authorized?
      request!(nil, "/specific_mocks/action_group_action_2", reader)
      assert !last_endpoint.authorized?
    end

    def test_filter_access
      assert SpecificMocks.top_level_setting.namespace_stackable[:befores].any?

      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test
            has_permission_on :specific_mocks, :to => 'GET /specific_mocks/show'
          end
        end
      }

      request!(MockUser.new(:test_role), "/specific_mocks/test_action", reader)
      assert last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/specific_mocks/test_action_2", reader)
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role_2), "/specific_mocks/test_action", reader)
      assert_equal 403, last_response.status
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/specific_mocks/show", reader)
      assert last_endpoint.authorized?
    end

    def test_filter_access_multi_actions
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test
          end
        end
      }
      request!(MockUser.new(:test_role), "/specific_mocks/create", reader)
      assert last_endpoint.authorized?
    end

    def test_filter_access_unprotected_actions
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
          end
        end
      }
      request!(MockUser.new(:test_role), "/specific_mocks/unprotected_action", reader)
      assert last_endpoint.authorized?
    end

    def test_filter_access_priv_hierarchy
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        privileges do
          privilege :read do
            includes "GET /specific_mocks/list", "GET /specific_mocks/show"
          end
        end
        authorization do
          role :test_role do
            has_permission_on :specific_mocks, :to => :read
          end
        end
      }
      request!(MockUser.new(:test_role), "/specific_mocks/show", reader)
      assert last_endpoint.authorized?
    end

    def test_filter_access_skip_attribute_test
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test do
              if_attribute :id => is { user }
            end
          end
        end
      }
      request!(MockUser.new(:test_role), "/specific_mocks/new", reader)
      assert last_endpoint.authorized?
    end

    def test_existing_instance_var_remains_unchanged
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test do
              if_attribute :id => is { 5 }
            end
          end
        end
      }
      mock_object = MockDataObject.new(:id => 5)

      request!(MockUser.new(:test_role), "/specific_mocks/edit_2", reader) do |endpoint|
        endpoint.send(:instance_variable_set, :"@load_mock_object", mock_object)
      end
      assert_equal mock_object, last_endpoint.send(:instance_variable_get, :"@load_mock_object")
      assert last_endpoint.authorized?
    end

    def test_permitted_to_without_context
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :specific_mocks, :to => :test
          end
        end
      }

      # Make any request so we can get a reference to an endpoint
      request!(MockUser.new(:test_role), "/specific_mocks/show", reader)

      assert last_endpoint.permitted_to?(:test)
    end

    def test_authorization_denied_callback_is_called_on_denial
      called_args = nil
      Authorization.config.authorization_denied_callback = proc do |details|
        called_args = details
      end
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test
          end
        end
      }
      # User does not have permission for test_action_2
      request!(MockUser.new(:test_role), "/specific_mocks/test_action_2", reader)
      assert !last_endpoint.authorized?
      assert called_args, "authorization_denied_callback should have been called"
      assert_equal "permissions_2", called_args[:context]
      assert_equal "GET", called_args[:action]
      assert_equal "/specific_mocks/test_action_2", called_args[:path]
      assert_equal false, called_args[:attribute_check_denial]
    ensure
      Authorization.config.authorization_denied_callback = nil
    end
  end

  ##################
  class AllMocks < MocksAPIInstance
    filter_access_to :all
    filter_access_to 'GET /all_mocks/view', :require => :test, :context => :permissions
    define_action_methods :show, :view
  end

  class AllActionsAPITest < ApiTestCase
    tests AllMocks

    def test_filter_access_all
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test
            has_permission_on :all_mocks, :to => 'GET /all_mocks/show'
          end
        end
      }

      request!(MockUser.new(:test_role), "/all_mocks/show", reader)
      assert last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/all_mocks/view", reader)
      assert last_endpoint.authorized?

      request!(MockUser.new(:test_role_2), "/all_mocks/show", reader)
      assert !last_endpoint.authorized?
    end
  end

  ##################
  class LoadMockObjects < MocksAPI
    filter_access_to 'GET /load_mock_objects/:id', :attribute_check => true, :model => LoadMockObject
    filter_access_to 'GET /load_mock_objects/:id/edit', :attribute_check => true
    filter_access_to 'PUT /load_mock_objects/:id', 'DELETE /load_mock_objects/:id', :attribute_check => true,
                     :load_method => proc {MockDataObject.new(:test => 1)}
    filter_access_to 'POST /load_mock_objects' do
      permitted_to! 'GET /load_mock_objects/:id/edit', :load_mock_objects
    end
    filter_access_to 'GET /load_mock_objects/view', :attribute_check => true, :load_method => :load_method

    helpers do
      @load_method_call_count = 0

      def load_method_call_count
        @load_method_call_count || 0
      end

      def load_method
        @load_method_call_count ||= 0
        @load_method_call_count += 1
        MockDataObject.new(:test => 2)
      end
    end

    resources :load_mock_objects do
      get :view do
        @authorized = true
        'nothing'
      end

      route_param :id do
        get do
          @authorized = true
          'nothing'
        end

        get :edit do
          @authorized = true
          'nothing'
        end

        put do
          @authorized = true
          'nothing'
        end

        delete do
          @authorized = true
          'nothing'
        end
      end

      post do
        @authorized = true
        'nothing'
      end
    end
  end

  class LoadObjectAPITest < ApiTestCase
    tests LoadMockObjects

    def test_filter_access_with_object_load
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :load_mock_objects, :to => [
              'GET /load_mock_objects/:id',
              'GET /load_mock_objects/:id/edit'
            ] do
              if_attribute :id => 1
              if_attribute :id => "1"
            end
          end
        end
      }

      request!(MockUser.new(:test_role), "/load_mock_objects/2", reader)
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/load_mock_objects/1", reader,
        :clear => [:@load_mock_object])
      assert last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/load_mock_objects/1/edit", reader,
        :clear => [:@load_mock_object])
      assert last_endpoint.authorized?
      assert last_endpoint.instance_variable_defined?(:@load_mock_object)
    end

    def test_filter_access_with_object_load_custom
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :load_mock_objects, :to => 'GET /load_mock_objects/view' do
              if_attribute :test => is {2}
            end
            has_permission_on :load_mock_objects, :to => 'PUT /load_mock_objects/:id' do
              if_attribute :test => is {1}
            end
            has_permission_on :load_mock_objects, :to => 'DELETE /load_mock_objects/:id' do
              if_attribute :test => is {2}
            end
          end
        end
      }

      request!(MockUser.new(:test_role), "/load_mock_objects/1", reader, :method => :delete)
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/load_mock_objects/view", reader)
      assert last_endpoint.authorized?
      assert_equal 1, last_endpoint.load_method_call_count

      request!(MockUser.new(:test_role_2), "/load_mock_objects/view", reader)
      assert !last_endpoint.authorized?
      assert_equal 1, last_endpoint.load_method_call_count

      # Test the custom load_object method on the `PUT /load_mock_objects/:id` action
      request!(MockUser.new(:test_role), "/load_mock_objects/123", reader, :method => :put)
      assert last_endpoint.authorized?
    end

    def test_filter_access_custom
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :load_mock_objects, :to => 'GET /load_mock_objects/:id/edit'
          end
          role :test_role_2 do
            has_permission_on :load_mock_objects, :to => 'POST /load_mock_objects'
          end
        end
      }

      request!(MockUser.new(:test_role), "/load_mock_objects", reader, :method => :post)
      assert last_endpoint.authorized?

      request!(MockUser.new(:test_role_2), "/load_mock_objects", reader, :method => :post)
      assert !last_endpoint.authorized?
    end
  end

  ##################
  class AccessOverwrites < MocksAPI
    filter_access_to 'GET /access_overwrites/test_action', 'GET /access_overwrites/test_action_2',
      :require => :test, :context => :permissions_2
    filter_access_to 'GET /access_overwrites/test_action', :require => :test, :context => :permissions
    define_action_methods :test_action, :test_action_2
  end

  class AccessOverwritesAPITest < ApiTestCase
    tests AccessOverwrites

    def test_filter_access_overwrite
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :permissions, :to => :test
          end
        end
      }
      request!(MockUser.new(:test_role), "/access_overwrites/test_action_2", reader)
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/access_overwrites/test_action", reader)
      assert last_endpoint.authorized?
    end
  end

  ##################
  class People < MocksAPI
    filter_access_to :all
    define_action_methods :show
  end

  class PeopleAPITest < ApiTestCase
    tests People

    def test_filter_access_people_controller
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :people, :to => 'GET /people/show'
          end
        end
      }
      request!(MockUser.new(:test_role), "/people/show", reader)
      assert last_endpoint.authorized?
    end
  end

  ##################
  class CommonAPI < MocksAPI
    filter_access_to :delete, :context => :common
    filter_access_to :all
  end
  class CommonChild1API < CommonAPI
    filter_access_to :all, :context => :context_1
  end
  class CommonChild2 < CommonAPI
    filter_access_to :delete
    define_action_methods :show, :delete
  end

  class HierachicalAPITest < ApiTestCase
    tests CommonChild2

    def test_controller_hierarchy
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :mocks, :to => ["GET /common_child_2/delete", "GET /common_child_2/show"]
          end
        end
      }

      request!(MockUser.new(:test_role), "/common_child2/show", reader)
      assert !last_endpoint.authorized?

      request!(MockUser.new(:test_role), "/common_child2/delete", reader)
      assert !last_endpoint.authorized?
    end
  end

  ##################
  module Name
    class SpacedThings < MocksAPI
      filter_access_to 'GET /name/spaced_things/show'
      filter_access_to 'GET /name/spaced_things/update', :context => :spaced_things
      define_action_methods :show, :update
    end
  end

  class NameSpacedAPITest < ApiTestCase
    tests Name::SpacedThings

    def test_context
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :permitted_role do
            has_permission_on :name_spaced_things, :to => "GET /name/spaced_things/show"
            has_permission_on :spaced_things, :to => "GET /name/spaced_things/update"
          end
          role :prohibited_role do
            has_permission_on :name_spaced_things, :to => "GET /name/spaced_things/update"
            has_permission_on :spaced_things, :to => "GET /name/spaced_things/show"
          end
        end
      }
      request!(MockUser.new(:permitted_role), "/name/spaced_things/show", reader)
      assert last_endpoint.authorized?
      request!(MockUser.new(:prohibited_role), "/name/spaced_things/show", reader)
      assert !last_endpoint.authorized?
      request!(MockUser.new(:permitted_role), "/name/spaced_things/update", reader)
      assert last_endpoint.authorized?
      request!(MockUser.new(:prohibited_role), "/name/spaced_things/update", reader)
      assert !last_endpoint.authorized?
    end
  end

  module Deep
    module NameSpaced
      class Things < MocksAPI
        filter_access_to 'GET /deep/name_spaced/things/show'
        filter_access_to 'GET /deep/name_spaced/things/update', :context => :things
        define_action_methods :show, :update
      end
    end
  end

  class DeepNameSpacedAPITest < ApiTestCase
    tests Deep::NameSpaced::Things

    def test_context
      reader = Authorization::Reader::DSLReader.new
      reader.parse %{
        authorization do
          role :permitted_role do
            has_permission_on :deep_name_spaced_things, :to => 'GET /deep/name_spaced/things/show'
            has_permission_on :things, :to => 'GET /deep/name_spaced/things/update'
          end
          role :prohibited_role do
            has_permission_on :deep_name_spaced_things, :to => 'GET /deep/name_spaced/things/update'
            has_permission_on :things, :to => 'GET /deep/name_spaced/things/show'
          end
        end
      }
      request!(MockUser.new(:permitted_role), "/deep/name_spaced/things/show", reader)
      assert last_endpoint.authorized?
      request!(MockUser.new(:prohibited_role), "/deep/name_spaced/things/show", reader)
      assert !last_endpoint.authorized?
      request!(MockUser.new(:permitted_role), "/deep/name_spaced/things/update", reader)
      assert last_endpoint.authorized?
      request!(MockUser.new(:prohibited_role), "/deep/name_spaced/things/update", reader)
      assert !last_endpoint.authorized?
    end
  end
end
