module Authorization
  module Controller
    module Runtime
      # If attribute_check is set for filter_access_to, decl_auth_context will try to
      # load the appropriate object from the current controller's model with
      # the id from params[:id].  If that fails, a 404 Not Found is often the
      # right way to handle the error.  If you have additional measures in place
      # that restricts the find scope, handling this error as a permission denied
      # might be a better way.  Set failed_auto_loading_is_not_found to false
      # for the latter behavior.
      @@failed_auto_loading_is_not_found = true
      def self.failed_auto_loading_is_not_found?
        @@failed_auto_loading_is_not_found
      end
      def self.failed_auto_loading_is_not_found=(new_value)
        @@failed_auto_loading_is_not_found = new_value
      end

      # Returns the Authorization::Engine for the current controller.
      def authorization_engine
        @authorization_engine ||= Authorization::Engine.instance
      end

      # If the current user meets the given privilege, permitted_to? returns true
      # and yields to the optional block.  The attribute checks that are defined
      # in the authorization rules are only evaluated if an object is given
      # for context.
      #
      # See examples for Authorization::AuthorizationHelper #permitted_to?
      #
      # If no object or context is specified, the controller_name is used as
      # context.
      #
      def permitted_to?(privilege, object_or_sym = nil, options = {})
        if authorization_engine.permit!(privilege, options_for_permit(object_or_sym, options, false))
          yield if block_given?
          true
        else
          false
        end
      end

      # Works similar to the permitted_to? method, but
      # throws the authorization exceptions, just like Engine#permit!
      def permitted_to!(privilege, object_or_sym = nil, options = {})
        authorization_engine.permit!(privilege, options_for_permit(object_or_sym, options, true))
      end

      # While permitted_to? is used for authorization, in some cases
      # content should only be shown to some users without being concerned
      # with authorization.  E.g. to only show the most relevant menu options
      # to a certain group of users.  That is what has_role? should be used for.
      def has_role?(*roles)
        user_roles = authorization_engine.roles_for(current_user)
        result = roles.all? do |role|
          user_roles.include?(role)
        end
        yield if result and block_given?
        result
      end

      # Intended to be used where you want to allow users with any single listed role to view
      # the content in question
      def has_any_role?(*roles)
        user_roles = authorization_engine.roles_for(current_user)
        result = roles.any? do |role|
          user_roles.include?(role)
        end
        yield if result and block_given?
        result
      end

      # As has_role? except checks all roles included in the role hierarchy
      def has_role_with_hierarchy?(*roles)
        user_roles = authorization_engine.roles_with_hierarchy_for(current_user)
        result = roles.all? do |role|
          user_roles.include?(role)
        end
        yield if result and block_given?
        result
      end

      # As has_any_role? except checks all roles included in the role hierarchy
      def has_any_role_with_hierarchy?(*roles)
        user_roles = authorization_engine.roles_with_hierarchy_for(current_user)
        result = roles.any? do |role|
          user_roles.include?(role)
        end
        yield if result and block_given?
        result
      end

      def options_for_permit(object_or_sym = nil, options = {}, bang = true)
        context = object = nil
        if object_or_sym.nil?
          context = decl_auth_context
        elsif !Authorization.is_a_association_proxy?(object_or_sym) and object_or_sym.is_a?(Symbol)
          context = object_or_sym
        else
          object = object_or_sym
        end

        result = {:object => object,
          :context => context,
          :skip_attribute_test => object.nil?,
          :bang => bang}.merge(options)
        result[:user] = current_user unless result.key?(:user)
        result
      end
    end
  end
end
