require File.join(%w{declarative_authorization helper})
if defined?(ActionController)
  require File.dirname(__FILE__) + '/declarative_authorization/controller/rails.rb'
end

if defined?(ActiveRecord)
  require File.join(%w{declarative_authorization in_model})
  require File.join(%w{declarative_authorization obligation_scope})
end

require File.join(%w{declarative_authorization railsengine}) if defined?(::Rails::Engine)

if defined?(ActionController)
  ActionController::Base.send :include, Authorization::Controller::Rails
  ActionController::Base.helper Authorization::AuthorizationHelper
end

ActiveRecord::Base.send :include, Authorization::AuthorizationInModel if defined?(ActiveRecord)
