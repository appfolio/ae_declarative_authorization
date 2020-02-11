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
            begin
              route
            rescue
              # Acceessing route raises an exception when the response is a 405 MethodNotAllowed
              return
            end
            unless allowed?("#{request.request_method} #{route.origin}")
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

          def api_class
            if options[:for].respond_to?(:base)
              # Grape >= 1.2.0 endpoint
              # Authorization::Controller::Grape can be included into either Grape::API
              # or Grape::API::Instance, so we need to check both.
              [
                options[:for],
                options[:for].base
              ].detect { |api| api.respond_to?(:decl_auth_context) }
            else
              # Grape < 1.2.0 endpoint
              options[:for]
            end
          end
        end
      end

      module ClassMethods
        def controller_name
          name.demodulize.underscore
        end

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
