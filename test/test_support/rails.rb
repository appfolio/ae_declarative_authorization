require DA_ROOT + File.join(%w{lib declarative_authorization controller rails})

if Rails.version < '4.2'
  raise "Unsupported Rails version #{Rails.version}"
end

puts "Testing against rails #{Rails::VERSION::STRING}"

class TestApp
  class Application < ::Rails::Application
    config.eager_load                 = false
    config.secret_key_base            = 'testingpurposesonly'
    config.active_support.deprecation = :stderr
    config.paths['config/database']   = File.expand_path('../../database.yml', __FILE__)
    config.active_support.test_order  = :random
    config.active_record.legacy_connection_handling = false if Rails.version >= '7'
    initialize!
  end
end

class MocksController < ActionController::Base
  attr_accessor :current_user
  attr_writer :authorization_engine

  def authorized?
    !!@authorized
  end

  def self.define_action_methods(*methods)
    methods.each do |method|
      define_method method do
        @authorized = true
        render :plain => 'nothing'
      end
    end
  end

  def self.define_resource_actions
    define_action_methods :index, :show, :edit, :update, :new, :create, :destroy
  end

  def logger(*args)
    Class.new do
      def warn(*args)
        #p args
      end
      alias_method :info, :warn
      alias_method :debug, :warn
      def warn?; end
      alias_method :info?, :warn?
      alias_method :debug?, :warn?
    end.new
  end
end

class ApplicationController < ActionController::Base
end

Rails.application.routes.draw do
  match '/name/spaced_things(/:action)' => 'name/spaced_things', via: [:get, :post, :put, :patch, :delete]
  match '/deep/name_spaced/things(/:action)' => 'deep/name_spaced/things', via: [:get, :post, :put, :patch, :delete]
  match '/:controller(/:action(/:id))', via: [:get, :post, :put, :patch, :delete]
end

ActionController::Base.send :include, Authorization::Controller::Rails
