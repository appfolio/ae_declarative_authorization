require File.dirname(__FILE__) + '/../controller_permission.rb'

module Authorization
  module Controller
    module DSL
      #
      # Defines a filter to be applied according to the authorization of the
      # current user.  Requires at least one symbol corresponding to an
      # action as parameter.  The special symbol :+all+ refers to all actions.
      # The all :+all+ statement is only employed if no specific statement is
      # present.
      #   class UserController < ApplicationController
      #     filter_access_to :index
      #     filter_access_to :new, :edit
      #     filter_access_to :all
      #     ...
      #   end
      #
      # The default is to allow access unconditionally if no rule matches.
      # Thus, including the +filter_access_to+ :+all+ statement is a good
      # idea, implementing a default-deny policy.
      #
      # When the access is denied, the method +permission_denied+ is called
      # on the current controller, if defined.  Else, a simple "you are not
      # allowed" string is output.  Log.info is given more information on the
      # reasons of denial.
      #
      #   def permission_denied
      #     flash[:error] = 'Sorry, you are not allowed to the requested page.'
      #     respond_to do |format|
      #       format.html { redirect_to(:back) rescue redirect_to('/') }
      #       format.xml  { head :unauthorized }
      #       format.js   { head :unauthorized }
      #     end
      #   end
      #
      # By default, required privileges are inferred from the action name and
      # the controller name.  Thus, in UserController :+edit+ requires
      # :+edit+ +users+.  To specify required privilege, use the option :+require+
      #   filter_access_to :new, :create, :require => :create, :context => :users
      #
      # Without the :+attribute_check+ option, no constraints from the
      # authorization rules are enforced because for some actions (collections,
      # +new+, +create+), there is no object to evaluate conditions against.  To
      # allow attribute checks on all actions, it is a common pattern to provide
      # custom objects through +before_actions+:
      #   class BranchesController < ApplicationController
      #     before_action :load_company
      #     before_action :new_branch_from_company_and_params,
      #       :only => [:index, :new, :create]
      #     filter_access_to :all, :attribute_check => true
      #
      #     protected
      #     def new_branch_from_company_and_params
      #       @branch = @company.branches.new(params[:branch])
      #     end
      #   end
      # NOTE: +before_actions+ need to be defined before the first
      # +filter_access_to+ call.
      #
      # For further customization, a custom filter expression may be formulated
      # in a block, which is then evaluated in the context of the controller
      # on a matching request.  That is, for checking two objects, use the
      # following:
      #   filter_access_to :merge do
      #     permitted_to!(:update, User.find(params[:original_id])) and
      #       permitted_to!(:delete, User.find(params[:id]))
      #   end
      # The block should raise a Authorization::AuthorizationError or return
      # false if the access is to be denied.
      #
      # Later calls to filter_access_to with overlapping actions overwrite
      # previous ones for that action.
      #
      # All options:
      # [:+require+]
      #   Privilege required; defaults to action_name
      # [:+context+]
      #   The privilege's context, defaults to decl_auth_context, which consists
      #   of controller_name, prepended by any namespaces
      # [:+attribute_check+]
      #   Enables the check of attributes defined in the authorization rules.
      #   Defaults to false.  If enabled, filter_access_to will use a context
      #   object from one of the following sources (in that order):
      #   * the method from the :+load_method+ option,
      #   * an instance variable named after the singular of the context
      #     (by default from the controller name, e.g. @post for PostsController),
      #   * a find on the context model, using +params+[:id] as id value.
      #   Any of these methods will only be employed if :+attribute_check+
      #   is enabled.
      # [:+model+]
      #   The data model to load a context object from.  Defaults to the
      #   context, singularized.
      # [:+load_method+]
      #   Specify a method by symbol or a Proc object which should be used
      #   to load the object.  Both should return the loaded object.
      #   If a Proc object is given, e.g. by way of
      #   +lambda+, it is called in the instance of the controller.
      #   Example demonstrating the default behavior:
      #     filter_access_to :show, :attribute_check => true,
      #                      :load_method => lambda { User.find(params[:id]) }
      #

      def filter_access_to(*args, &filter_block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = {
          :require => nil,
          :context => nil,
          :attribute_check => false,
          :model => nil,
          :load_method => nil,
          :strong_parameters => nil
        }.merge!(options)
        privilege = options[:require]
        context = options[:context]
        actions = args.flatten

        reset_filter!

        filter_access_permissions.each do |perm|
          perm.remove_actions(actions)
        end
        filter_access_permissions <<
          ControllerPermission.new(actions, privilege, context,
                                   options[:strong_parameters],
                                   options[:attribute_check],
                                   options[:model],
                                   options[:load_method],
                                   filter_block)
      end

      # Disables authorization entirely.  Requires at least one symbol corresponding
      # to an action as parameter.  The special symbol :+all+ refers to all actions.
      # The all :+all+ statement is only employed if no specific statement is
      # present.
      def no_filter_access_to(*args)
        filter_access_to args do
          true
        end
      end

      # Collecting all the ControllerPermission objects from the controller
      # hierarchy.  Permissions for actions are overwritten by calls to
      # filter_access_to in child controllers with the same action.
      def all_filter_access_permissions # :nodoc:
        ancestors.inject([]) do |perms, mod|
          if mod.respond_to?(:filter_access_permissions, true)
            perms +
              mod.filter_access_permissions.collect do |p1|
                p1.clone.remove_actions(perms.inject(Set.new) {|actions, p2| actions + p2.actions})
              end
          else
            perms
          end
        end
      end

      # Returns the context for authorization checks in the current controller.
      # Uses the controller_name and prepends any namespaces underscored and
      # joined with underscores.
      #
      # E.g.
      #   AllThosePeopleController         => :all_those_people
      #   AnyName::Space::ThingsController => :any_name_space_things
      #
      def decl_auth_context
        prefixes = name.split('::')[0..-2].map(&:underscore)
        ((prefixes + [controller_name]) * '_').to_sym
      end

      protected

      def filter_access_permissions # :nodoc:
        unless filter_access_permissions?
          ancestors[1..-1].reverse.each do |mod|
            mod.filter_access_permissions if mod.respond_to?(:filter_access_permissions, true)
          end
        end
        class_variable_set(:@@declarative_authorization_permissions, {}) unless filter_access_permissions?
        class_variable_get(:@@declarative_authorization_permissions)[self.name] ||= []
      end

      def filter_access_permissions? # :nodoc:
        class_variable_defined?(:@@declarative_authorization_permissions)
      end

      def actions_from_option(option) # :nodoc:
        case option
        when nil
          {}
        when Symbol, String
          {option.to_sym => option.to_sym}
        when Hash
          option
        when Enumerable
          option.each_with_object({}) do |action, hash|
            if action.is_a?(Array)
              raise "Unexpected option format: #{option.inspect}" if action.length != 2
              hash[action.first] = action.last
            else
              hash[action.to_sym] = action.to_sym
            end
          end
        end
      end
    end
  end
end
