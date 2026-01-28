# Authorization::AuthorizationHelper
require "#{File.dirname(__FILE__)}/authorization.rb"

module Authorization
  # Include this module in your views
  module AuthorizationHelper
    delegate :has_role?, :has_role_with_hierarchy?,
             :has_any_role?, :has_any_role_with_hierarchy?,
             :permitted_to?,
             to: :controller
  end
end
