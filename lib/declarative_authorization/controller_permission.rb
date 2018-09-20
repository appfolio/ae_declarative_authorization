module Authorization
  class ControllerPermission # :nodoc:
    attr_reader :actions, :privilege, :context, :attribute_check, :strong_params
    def initialize(actions, privilege, context, strong_params, attribute_check = false,
                    load_object_model = nil, load_object_method = nil,
                    filter_block = nil)
      @actions = actions.to_set
      @privilege = privilege
      @context = context
      @load_object_model = load_object_model
      @load_object_method = load_object_method
      @filter_block = filter_block
      @attribute_check = attribute_check
      @strong_params = strong_params
    end

    def matches?(action_name)
      @actions.include?(action_name.to_sym)
    end

    def permit!(contr)
      if @filter_block
        return contr.instance_eval(&@filter_block)
      end
      object = @attribute_check ? load_object(contr) : nil
      privilege = @privilege || :"#{contr.action_name}"

      contr.authorization_engine.permit!(privilege,
                                         :user => contr.send(:current_user),
                                         :object => object,
                                         :skip_attribute_test => !@attribute_check,
                                         :context => @context || contr.class.decl_auth_context)
    end

    def remove_actions(actions)
      @actions -= actions
      self
    end

    private

    def load_object(contr)
      if @load_object_method and @load_object_method.is_a?(Symbol)
        contr.send(@load_object_method)
      elsif @load_object_method and @load_object_method.is_a?(Proc)
        contr.instance_eval(&@load_object_method)
      else
        load_object_model = @load_object_model ||
            (@context ? @context.to_s.classify.constantize : contr.class.controller_name.classify.constantize)
        load_object_model = load_object_model.classify.constantize if load_object_model.is_a?(String)
        instance_var = "@#{load_object_model.name.demodulize.underscore}"
        object = contr.instance_variable_get(instance_var)
        unless object
          begin
            object = @strong_params ? load_object_model.find_or_initialize_by(:id => contr.params[:id]) : load_object_model.find(contr.params[:id])
          rescue => e
            contr.logger.debug("filter_access_to tried to find " +
                "#{load_object_model} from params[:id] " +
                "(#{contr.params[:id].inspect}), because attribute_check is enabled " +
                "and #{instance_var.to_s} isn't set, but failed: #{e.class.name}: #{e}")
            raise if Authorization::Controller::Runtime.failed_auto_loading_is_not_found?
          end
          contr.instance_variable_set(instance_var, object)
        end
        object
      end
    end
  end
end
