require 'test_helper'

class BasicPraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def test_filter_access_to_receiving_an_explicit_array
    reader = Authorization::Reader::DSLReader.new

    reader.parse %{
      authorization do
        role :test_action_group_2 do
          has_permission_on :praxis_dummy_controllers_basic, :to => :action_group_action_2
        end
      end
    }

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_action_group_2), "/praxis_test_engine/basic/action_group_action_2", reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_action_group_2), "/praxis_test_engine/basic/action_group_action_1", reader)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::Basic, nil, "/praxis_test_engine/basic/action_group_action_2", reader)
    assert_equal 403, response.status
  end

  def test_filter_access
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
          has_permission_on :praxis_dummy_controllers_basic, :to => :show_stuff
        end
      end
    }

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/test_action", reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/test_action_2", reader)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role_2), "/praxis_test_engine/basic/test_action_2", reader)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/show_stuff/99", reader)
    assert_equal 200, response.status
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

    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/", reader, method: :post)
    assert_equal 200, response.status
  end

  def test_filter_access_unprotected_actions
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
        end
      end
    }
    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/unprotected_action", reader)
    assert_equal 200, response.status
  end

  def test_filter_access_priv_hierarchy
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      privileges do
        privilege :read do
          includes :list, :show_stuff
        end
      end
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_basic, :to => :read
        end
      end
    }
    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/show_stuff/99", reader)
    assert_equal 200, response.status
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
    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/new", reader)
    assert_equal 200, response.status
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
    PraxisDummy::Controllers::Basic.any_instance.expects(:instance_variable_get).once.with('@mock_model').returns(PraxisDummy::Models::MockModel.new(id: 5))
    PraxisDummy::Controllers::Basic.any_instance.expects(:instance_variable_set).with('@mock_model', anything).never
    request!(PraxisDummy::Controllers::Basic, MockUser.new(:test_role), "/praxis_test_engine/basic/edit", reader)
    assert_equal 200, response.status
  end

  def test_permitted_to_without_context__no_current_user
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
        authorization do
          role :test_role do
            has_permission_on :praxis_dummy_controllers_basic, :to => :foo
          end
        end
      }
    PraxisDummy::Controllers::Basic.any_instance.stubs(:authorization_engine).returns(Authorization::Engine.new(reader))
    controller = PraxisDummy::Controllers::Basic.new({})
    assert_equal false, controller.permitted_to?(:foo)
    assert_equal false, controller.permitted_to?(:bar)
  end

  def test_permitted_to_without_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_basic, :to => :foo
        end
      end
    }
    PraxisDummy::Controllers::Basic.any_instance.stubs(:current_user).returns(MockUser.new(:test_role))
    PraxisDummy::Controllers::Basic.any_instance.stubs(:authorization_engine).returns(Authorization::Engine.new(reader))
    controller = PraxisDummy::Controllers::Basic.new({})
    assert controller.permitted_to?(:foo)
    assert_equal false, controller.permitted_to?(:bar)
  end
end


class FilterAccessToAllPraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def test_filter_access_all
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
          has_permission_on :praxis_dummy_controllers_all, :to => :show
        end
      end
    }

    request!(PraxisDummy::Controllers::All, MockUser.new(:test_role), '/praxis_test_engine/all/show', reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::All, MockUser.new(:test_role), '/praxis_test_engine/all/view', reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::All, MockUser.new(:test_role_2), '/praxis_test_engine/all/show', reader)
    assert_equal 403, response.status
  end
end


class LoadMethodPraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def teardown
    Authorization::AuthorizationInController.failed_auto_loading_is_not_found = true
  end

  def test_filter_access_with_object_load
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_load_method, :to => [:show, :edit] do
            if_attribute :id => 1
            if_attribute :id => "1"
          end
        end
      end
    }

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/show', reader, :id => 2)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/show', reader, :id => 1)
    assert_equal 200, response.status

    PraxisDummy::Controllers::LoadMethod.any_instance.expects(:instance_variable_set).once.with('@load_method', ::LoadMethod.new(id: 1))
    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/edit', reader, :id => 1)
    assert_equal 200, response.status
  end

  def test_filter_access_object_load_without_param
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_load_method, :to => [:show_id_not_required, :edit] do
            if_attribute :id => is {"1"}
          end
        end
      end
    }

    Authorization::AuthorizationInController.failed_auto_loading_is_not_found = true
    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/show_id_not_required', reader)
    assert_equal 500, response.status

    Authorization::AuthorizationInController.failed_auto_loading_is_not_found = false
    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/show_id_not_required', reader)
    assert_equal 403, response.status
  end

  def test_filter_access_with_object_load_custom
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_load_method, :to => :view do
            if_attribute :test => is {2}
          end
          has_permission_on :praxis_dummy_controllers_load_method, :to => :update do
            if_attribute :test => is {1}
          end
          has_permission_on :praxis_dummy_controllers_load_method, :to => :delete do
            if_attribute :test => is {2}
          end
        end
      end
    }

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/delete', reader)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/update', reader)
    assert_equal 200, response.status

    PraxisDummy::Controllers::LoadMethod.any_instance.expects(:load_method).twice.returns(PraxisDummy::Models::MockModel.new(test: 2))
    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/view', reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role_2), '/praxis_test_engine/load_method/view', reader)
    assert_equal 403, response.status
  end

  def test_filter_access_custom
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_load_method, :to => :edit
        end
        role :test_role_2 do
          has_permission_on :praxis_dummy_controllers_load_method, :to => :create
        end
      end
    }

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role), '/praxis_test_engine/load_method/create', reader)
    assert_equal 200, response.status

    request!(PraxisDummy::Controllers::LoadMethod, MockUser.new(:test_role_2), '/praxis_test_engine/load_method/create', reader)
    assert_equal 403, response.status
  end
end


class AccessOverwritePraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def test_filter_access_overwrite
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :permissions, :to => :test
        end

        role :test_role_2 do
          has_permission_on :permissions_2, :to => :test
        end
      end
    }
    request!(PraxisDummy::Controllers::Overwrite, MockUser.new(:test_role), '/praxis_test_engine/overwrite/test_action_2', reader)
    assert_equal 403, response.status

    request!(PraxisDummy::Controllers::Overwrite, MockUser.new(:test_role), '/praxis_test_engine/overwrite/test_action', reader)
    assert_equal 200, response.status
  end
end


class PluralizationPraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def test_filter_access_people_controller
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :test_role do
          has_permission_on :praxis_dummy_controllers_people, :to => :show
        end
      end
    }

    request!(PraxisDummy::Controllers::People, MockUser.new(:test_role), '/praxis_test_engine/people/show', reader)
    assert_equal 200, response.status
  end
end


class NameSpacedPraxisControllerTest < PraxisTestCase

  def setup
    header('X-API-Version', '1')
  end

  def test_context
    reader = Authorization::Reader::DSLReader.new
    reader.parse %{
      authorization do
        role :permitted_role do
          has_permission_on :praxis_dummy_controllers_name_spaced, :to => :show
          has_permission_on :name_spaced, :to => :update
        end
        role :prohibited_role do
          has_permission_on :praxis_dummy_controllers_name_spaced, :to => :update
          has_permission_on :name_spaced, :to => :show
        end
      end
    }
    request!(PraxisDummy::Controllers::NameSpaced, MockUser.new(:permitted_role), '/praxis_test_engine/name_spaced/show', reader)
    assert_equal 200, response.status
    request!(PraxisDummy::Controllers::NameSpaced, MockUser.new(:prohibited_role), '/praxis_test_engine/name_spaced/show', reader)
    assert 403, response.status
    request!(PraxisDummy::Controllers::NameSpaced, MockUser.new(:permitted_role), '/praxis_test_engine/name_spaced/update', reader)
    assert_equal 200, response.status
    request!(PraxisDummy::Controllers::NameSpaced, MockUser.new(:prohibited_role), '/praxis_test_engine/name_spaced/update', reader)
    assert 403, response.status
  end
end
