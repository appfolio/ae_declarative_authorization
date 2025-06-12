require File.dirname(__FILE__) + '/../authorization.rb'
require File.dirname(__FILE__) + '/dsl.rb'
require File.dirname(__FILE__) + '/runtime.rb'

#
# Mixin to be added to rails controllers
#
module Authorization
  module Controller
    module Rails
      def self.included(base) # :nodoc:
        base.extend ClassMethods

        base.extend DSL

        base.module_eval do
          add_filter!
        end

        base.include Runtime
      end

      module ClassMethods
        #
        # Add the filtering before_action
        #
        def add_filter!
          before_action(:filter_access_filter)
        end

        #
        # Move the filtering to the end of the before_action list
        #
        def reset_filter!
          skip_before_action(:filter_access_filter) if method_defined?(:filter_access_filter)
          before_action :filter_access_filter
        end

        # To DRY up the filter_access_to statements in restful controllers,
        # filter_resource_access combines typical filter_access_to and
        # before_action calls, which set up the instance variables.
        #
        # The simplest case are top-level resource controllers with only the
        # seven CRUD methods, e.g.
        #   class CompanyController < ApplicationController
        #     filter_resource_access
        #
        #     def index...
        #   end
        # Here, all CRUD actions are protected through a filter_access_to :all
        # statement.  :+attribute_check+ is enabled for all actions except for
        # the collection action :+index+.  To have an object for attribute checks
        # available, filter_resource_access will set the instance variable
        # @+company+ in before filters.  For the member actions (:+show+, :+edit+,
        # :+update+, :+destroy+) @company is set to Company.find(params[:id]).
        # For +new+ actions (:+new+, :+create+), filter_resource_access creates
        # a new object from company parameters: Company.new(params[:company].
        #
        # For nested resources, the parent object may be loaded automatically.
        #   class BranchController < ApplicationController
        #     filter_resource_access :nested_in => :companies
        #   end
        # Again, the CRUD actions are protected.  Now, for all CRUD actions,
        # the parent object @company is loaded from params[:company_id].  It is
        # also used when creating @branch for +new+ actions.  Here, attribute_check
        # is enabled for the collection :+index+ as well, checking attributes on a
        # @company.branches.new method.
        #
        # In many cases, the default seven CRUD actions are not sufficient.  As in
        # the resource definition for routing you may thus give additional member,
        # new and collection methods.  The +options+ allow you to specify the
        # required privileges for each action by providing a hash or an array of
        # pairs.  By default, for each action the action name is taken as privilege
        # (action search in the example below requires the privilege :index
        # :companies).  Any controller action that is not specified and does not
        # belong to the seven CRUD actions is handled as a member method.
        #   class CompanyController < ApplicationController
        #     filter_resource_access :collection => [[:search, :index], :index],
        #         :additional_member => {:mark_as_key_company => :update}
        #   end
        # The +additional_+* options add to the respective CRUD actions,
        # the other options (:+member+, :+collection+, :+new+) replace their
        # respective CRUD actions.
        #    filter_resource_access :member => { :toggle_open => :update }
        # Would declare :toggle_open as the only member action in the controller and
        # require that permission :update is granted for the current user.
        #    filter_resource_access :additional_member => { :toggle_open => :update }
        # Would add a member action :+toggle_open+ to the default members, such as :+show+.
        #
        # If :+collection+ is an array of method names filter_resource_access will
        # associate a permission with the method that is the same as the method
        # name and no attribute checks will be performed unless
        #   :attribute_check => true
        # is added in the options.
        #
        # You can override the default object loading by implementing any of the
        # following instance methods on the controller.  Examples are given for the
        # BranchController (with +nested_in+ set to :+companies+):
        # [+new_branch_from_params+]
        #   Used for +new+ actions.
        # [+new_branch_for_collection+]
        #   Used for +collection+ actions if the +nested_in+ option is set.
        # [+load_branch+]
        #   Used for +member+ actions.
        # [+load_company+]
        #   Used for all +new+, +member+, and +collection+ actions if the
        #   +nested_in+ option is set.
        #
        # All options:
        # [:+member+]
        #   Member methods are actions like +show+, which have an params[:id] from
        #   which to load the controller object and assign it to @controller_name,
        #   e.g. @+branch+.
        #
        #   By default, member actions are [:+show+, :+edit+, :+update+,
        #   :+destroy+].  Also, any action not belonging to the seven CRUD actions
        #   are handled as member actions.
        #
        #   There are three different syntax to specify member, collection and
        #   new actions.
        #   * Hash:  Lets you set the required privilege for each action:
        #     {:+show+ => :+show+, :+mark_as_important+ => :+update+}
        #   * Array of actions or pairs: [:+show+, [:+mark_as_important+, :+update+]],
        #     with single actions requiring the privilege of the same name as the method.
        #   * Single method symbol: :+show+
        # [:+additional_member+]
        #   Allows to add additional member actions to the default resource +member+
        #   actions.
        # [:+collection+]
        #   Collection actions are like :+index+, actions without any controller object
        #   to check attributes of.  If +nested_in+ is given, a new object is
        #   created from the parent object, e.g. @company.branches.new.  Without
        #   +nested_in+, attribute check is deactivated for these actions.  By
        #   default, collection is set to :+index+.
        # [:+additional_collection+]
        #   Allows to add additional collection actions to the default resource +collection+
        #   actions.
        # [:+new+]
        #   +new+ methods are actions such as +new+ and +create+, which don't
        #   receive a params[:id] to load an object from, but
        #   a params[:controller_name_singular] hash with attributes for a new
        #   object.  The attributes will be used here to create a new object and
        #   check the object against the authorization rules.  The object is
        #   assigned to @controller_name_singular, e.g. @branch.
        #
        #   If +nested_in+ is given, the new object
        #   is created from the parent_object.controller_name
        #   proxy, e.g. company.branches.new(params[:branch]).  By default,
        #   +new+ is set to [:new, :create].
        # [:+additional_new+]
        #   Allows to add additional new actions to the default resource +new+ actions.
        # [:+context+]
        #   The context is used to determine the model to load objects from for the
        #   before_actions and the context of privileges to use in authorization
        #   checks.
        # [:+nested_in+]
        #   Specifies the parent controller if the resource is nested in another
        #   one.  This is used to automatically load the parent object, e.g.
        #   @+company+ from params[:company_id] for a BranchController nested in
        #   a CompanyController.
        # [:+shallow+]
        #   Only relevant when used in conjunction with +nested_in+. Specifies a nested resource
        #   as being a shallow nested resource, resulting in the controller not attempting to
        #   load a parent object for all member actions defined by +member+ and
        #   +additional_member+ or rather the default member actions (:+show+, :+edit+,
        #   :+update+, :+destroy+).
        # [:+no_attribute_check+]
        #   Allows to set actions for which no attribute check should be performed.
        #   See filter_access_to on details.  By default, with no +nested_in+,
        #   +no_attribute_check+ is set to all collections.  If +nested_in+ is given
        #   +no_attribute_check+ is empty by default.
        # [:+strong_parameters+]
        #   If set to true, relies on controller to provide instance variable and
        #   create new object in :create action.  Set true if you use strong_params
        #   and false if you use protected_attributes.
        #
        def filter_resource_access(options = {})
          options = {
            :new        => [:new, :create],
            :additional_new => nil,
            :member     => [:show, :edit, :update, :destroy],
            :additional_member => nil,
            :collection => [:index],
            :additional_collection => nil,
            #:new_method_for_collection => nil,  # only symbol method name
            #:new_method => nil,                 # only symbol method name
            #:load_method => nil,                # only symbol method name
            :no_attribute_check => nil,
            :context    => nil,
            :model => nil,
            :nested_in  => nil,
            :strong_parameters => nil
          }.merge(options)
          options.merge!({ :strong_parameters => true }) if options[:strong_parameters] == nil

          new_actions = actions_from_option( options[:new] ).merge(
              actions_from_option(options[:additional_new]) )
          members = actions_from_option(options[:member]).merge(
              actions_from_option(options[:additional_member]))
          collections = actions_from_option(options[:collection]).merge(
              actions_from_option(options[:additional_collection]))

          no_attribute_check_actions = options[:strong_parameters] ? collections.merge(actions_from_option([:create])) : collections

          options[:no_attribute_check] ||= no_attribute_check_actions.keys unless options[:nested_in]

          unless options[:nested_in].blank?
            load_parent_method = :"load_#{options[:nested_in].to_s.singularize}"
            shallow_exceptions = options[:shallow] ? {:except => members.keys} : {}
            before_action shallow_exceptions do |controller|
              if controller.respond_to?(load_parent_method, true)
                controller.send(load_parent_method)
              else
                controller.send(:load_parent_controller_object, options[:nested_in])
              end
            end

            new_for_collection_method = :"new_#{controller_name.singularize}_for_collection"
            before_action :only => collections.keys do |controller|
              # new_for_collection
              if controller.respond_to?(new_for_collection_method, true)
                controller.send(new_for_collection_method)
              else
                controller.send(:new_controller_object_for_collection,
                    options[:context] || controller_name, options[:nested_in], options[:strong_parameters])
              end
            end
          end

          unless options[:strong_parameters]
            new_from_params_method = :"new_#{controller_name.singularize}_from_params"
            before_action :only => new_actions.keys do |controller|
              # new_from_params
              if controller.respond_to?(new_from_params_method, true)
                controller.send(new_from_params_method)
              else
                controller.send(:new_controller_object_from_params,
                    options[:context] || controller_name, options[:nested_in], options[:strong_parameters])
              end
            end
          else
            new_object_method = :"new_#{controller_name.singularize}"
            before_action :only => :new do |controller|
              # new_from_params
              if controller.respond_to?(new_object_method, true)
                controller.send(new_object_method)
              else
                controller.send(:new_blank_controller_object,
                    options[:context] || controller_name, options[:nested_in], options[:strong_parameters], options[:model])
              end
            end
          end

          load_method = :"load_#{controller_name.singularize}"
          before_action :only => members.keys do |controller|
            # load controller object
            if controller.respond_to?(load_method, true)
              controller.send(load_method)
            else
              controller.send(:load_controller_object, options[:context] || controller_name, options[:model])
            end
          end
          filter_access_to :all, :attribute_check => true, :context => options[:context], :model => options[:model]

          members.merge(new_actions).merge(collections).each do |action, privilege|
            if action != privilege or (options[:no_attribute_check] and options[:no_attribute_check].include?(action))
              filter_options = {
                :strong_parameters => options[:strong_parameters],
                :context          => options[:context],
                :attribute_check  => !options[:no_attribute_check] || !options[:no_attribute_check].include?(action),
                :model => options[:model]
              }
              filter_options[:require] = privilege if action != privilege
              filter_access_to(action, filter_options)
            end
          end
        end
      end

      protected

      def filter_access_filter # :nodoc:
        unless allowed?(action_name)
          if respond_to?(:permission_denied, true)
            # permission_denied needs to render or redirect
            send(:permission_denied)
          else
            render plain: 'You are not allowed to access this action.', status: :forbidden
          end
        end
      end

      def load_controller_object(context_without_namespace = nil, model = nil) # :nodoc:
        instance_var = :"@#{context_without_namespace.to_s.singularize}"
        model = model ? model.classify.constantize : context_without_namespace.to_s.classify.constantize
        instance_variable_set(instance_var, model.find(params[:id]))
      end

      def load_parent_controller_object(parent_context_without_namespace) # :nodoc:
        instance_var = :"@#{parent_context_without_namespace.to_s.singularize}"
        model = parent_context_without_namespace.to_s.classify.constantize
        instance_variable_set(instance_var, model.find(params[:"#{parent_context_without_namespace.to_s.singularize}_id"]))
      end

      def new_controller_object_from_params(context_without_namespace, parent_context_without_namespace, strong_params) # :nodoc:
        model_or_proxy = parent_context_without_namespace ?
             instance_variable_get(:"@#{parent_context_without_namespace.to_s.singularize}").send(context_without_namespace.to_sym) :
             context_without_namespace.to_s.classify.constantize
        instance_var = :"@#{context_without_namespace.to_s.singularize}"
        instance_variable_set(instance_var,
          model_or_proxy.new(params[context_without_namespace.to_s.singularize]))
      end

      def new_blank_controller_object(context_without_namespace, parent_context_without_namespace, strong_params, model) # :nodoc:
        if model
          model_or_proxy = model.to_s.classify.constantize
        else
          model_or_proxy = parent_context_without_namespace ?
          instance_variable_get(:"@#{parent_context_without_namespace.to_s.singularize}").send(context_without_namespace.to_sym) :
          context_without_namespace.to_s.classify.constantize
        end
        instance_var = :"@#{context_without_namespace.to_s.singularize}"
        instance_variable_set(instance_var,
          model_or_proxy.new())
      end

      def new_controller_object_for_collection(context_without_namespace, parent_context_without_namespace, strong_params) # :nodoc:
        model_or_proxy = parent_context_without_namespace ?
             instance_variable_get(:"@#{parent_context_without_namespace.to_s.singularize}").send(context_without_namespace.to_sym) :
             context_without_namespace.to_s.classify.constantize
        instance_var = :"@#{context_without_namespace.to_s.singularize}"
        instance_variable_set(instance_var, model_or_proxy.new)
      end

      def api_class
        self.class
      end
    end
  end
end
