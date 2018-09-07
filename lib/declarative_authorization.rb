require File.join(%w{declarative_authorization helper})
require File.join(%w{declarative_authorization in_controller})
require File.join(%w{declarative_authorization in_praxis_controller})
if defined?(ActiveRecord)
  require File.join(%w{declarative_authorization in_model})
  require File.join(%w{declarative_authorization obligation_scope})
end

min_rails_version = '4.2.5.2'
if Rails::VERSION::STRING < min_rails_version
  raise "ae_declarative_authorization requires Rails #{min_rails_version}. You are using #{Rails::VERSION::STRING}."
end

require File.join(%w{declarative_authorization railsengine}) if defined?(::Rails::Engine)

ActionController::Base.send :include, Authorization::AuthorizationInController
ActionController::Base.helper Authorization::AuthorizationHelper

ActiveRecord::Base.send :include, Authorization::AuthorizationInModel if defined?(ActiveRecord)
