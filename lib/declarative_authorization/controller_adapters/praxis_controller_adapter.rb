module Authorization
  module AuthorizationInController
    module ControllerAdapters
      class PraxisControllerAdapter < ControllerAdapterBase

        def controller_name
          controller_instance.name.demodulize.snakecase
        end

        def action_name
          controller_instance.request.action.name
        end

        def params
          controller_instance.request.params
        end

        def logger
          controller_instance.request.env['action_dispatch.logger']
        end
      end
    end
  end
end
