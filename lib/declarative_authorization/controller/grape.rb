require File.dirname(__FILE__) + '/../authorization.rb'
require File.dirname(__FILE__) + '/dsl.rb'
require File.dirname(__FILE__) + '/runtime.rb'

#
# This mixin can be used to add declarative authorization support to APIs built using Grape
# https://github.com/ruby-grape/grape
#
# Usage:
#   class MyApi < Grape::API
#     include Authorization::Controller::Grape
#
#     get :hello do
#     end
#   end
#
# NOTE: actions in authorization rules must be named `{METHOD} {URL}`. eg
#   has_permission_on :my_api, to: 'GET /my_api/hello'
#
module Authorization
  module Controller
    module Grape
      def self.included(base) # :nodoc:
        base.extend ClassMethods

        base.extend ::Authorization::Controller::DSL

        base.module_eval do
          add_filter!
        end

        base.helpers do
          include ::Authorization::Controller::Runtime

          def authorization_engine
            ::Authorization::Engine.instance
          end

          def filter_access_filter # :nodoc:
            action_name = "#{request.request_method} #{route.origin}"

            permissions = api_class.all_filter_access_permissions
            all_permissions = permissions.select {|p| p.actions.include?(:all)}
            matching_permissions = permissions.select {|p| p.matches?(action_name)}
            allowed = false
            auth_exception = nil

            begin
              allowed = if !matching_permissions.empty?
                          matching_permissions.all? {|perm|
                            perm.permit!(self, action_name)
                        }
                        elsif !all_permissions.empty?
                          all_permissions.all? {|perm| perm.permit!(self, action_name)}
                        else
                          !DEFAULT_DENY
                        end
            rescue ::Authorization::NotAuthorized => e
              auth_exception = e
            end

            unless allowed
              if all_permissions.empty? and matching_permissions.empty?
                logger.warn "Permission denied: No matching filter access " +
                  "rule found for #{api_class.name}.#{action_name}"
              elsif auth_exception
                logger.info "Permission denied: #{auth_exception}"
              end
              if respond_to?(:permission_denied, true)
                # permission_denied needs to render or redirect
                send(:permission_denied)
              else
                error!('You are not allowed to access this action.', 403)
              end
            end
          end

          def logger
            ::Rails.logger
          end

          protected

          def api_class
            options[:for]
          end

          def decl_auth_context
            api_class.decl_auth_context
          end
        end
      end

      DEFAULT_DENY = false

      module ClassMethods
        def add_filter!
          before do
            send(:filter_access_filter)
          end
        end

        def reset_filter!
          # Not required with Grape
        end
      end
    end
  end
end
