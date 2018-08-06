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

    def permit!(controller_adapter)
      if @filter_block
        return controller_adapter.controller_instance_eval(@filter_block)
      end
      object = @attribute_check ? controller_adapter.load_object(context, strong_params, @load_object_model, @load_object_method) : nil
      privilege = @privilege || :"#{controller_adapter.action_name}"

      controller_adapter.authorization_engine.permit!(privilege,
                                         :user => controller_adapter.current_user,
                                         :object => object,
                                         :skip_attribute_test => !@attribute_check,
                                         :context => @context || controller_adapter.decl_auth_context)
    end

    def remove_actions(actions)
      @actions -= actions
      self
    end
  end
end
