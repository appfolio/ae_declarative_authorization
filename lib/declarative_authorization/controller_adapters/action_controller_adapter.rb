require File.dirname(__FILE__) + '/controller_adapter_base.rb'

module Authorization
  module AuthorizationInController
    module ControllerAdapters
      class ActionControllerAdapter < ControllerAdapterBase

        delegate :action_name, :params, :logger, to: :controller_instance

        def controller_name
          controller_instance.class.controller_name
        end
      end
    end
  end
end
