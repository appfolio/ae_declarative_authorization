module Authorization
  module AuthorizationInController
    module ControllerAdapters
      class ControllerAdapterBase

        attr_reader :controller_instance
        delegate :authorization_engine, :current_user, to: :controller_instance

        def initialize(instance)
          @controller_instance = instance
        end

        def controller_defines_permission_denied?
          controller_instance.respond_to?(:permission_denied, true)
        end

        def permission_denied
          controller_instance.permission_denied if controller_defines_permission_denied?
        end

        def all_filter_access_permissions
          controller_instance.class.all_filter_access_permissions
        end

        def controller_instance_eval(block)
          controller_instance.instance_eval(&block)
        end

        def decl_auth_context
          controller_instance.class.decl_auth_context
        end

        def load_object(context, strong_params, load_object_model = nil, load_object_method = nil)
          if load_object_method and load_object_method.is_a?(Symbol)
            controller_instance.send(load_object_method)
          elsif load_object_method and load_object_method.is_a?(Proc)
            controller_instance.instance_eval(&load_object_method)
          else
            load_object_model = load_object_model ||
              (context ? context.to_s.classify.constantize : controller_instance.controller_name.classify.constantize)
            load_object_model = load_object_model.classify.constantize if load_object_model.is_a?(String)
            instance_var = "@#{load_object_model.name.demodulize.underscore}"
            object = controller_instance.instance_variable_get(instance_var)
            unless object
              begin
                object = strong_params ? load_object_model.find_or_initialize_by(:id => controller_instance.params[:id]) : load_object_model.find(controller_instance.params[:id])
              rescue => e
                controller_instance.logger.debug("filter_access_to tried to find " +
                                     "#{load_object_model} from params[:id] " +
                                     "(#{controller_instance.params[:id].inspect}), because attribute_check is enabled " +
                                     "and #{instance_var.to_s} isn't set, but failed: #{e.class.name}: #{e}")
                raise if AuthorizationInController.failed_auto_loading_is_not_found?
              end
              controller_instance.instance_variable_set(instance_var, object)
            end
            object
          end
        end


        def action_name
          raise "Not Implemented"
        end

        def params
          raise "Not Implemented"
        end

        def logger
          raise "Not Implemented"
        end
      end
    end
  end
end
