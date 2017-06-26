require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'minitest/autorun'

ENV['RAILS_ENV'] = 'test'

require 'rails/all'
require 'test_support/minitest_compatibility'

if Rails.version < '4.2'
  raise "Unsupported Rails version #{Rails.version}"
end

puts "Testing against rails #{Rails::VERSION::STRING}"

if Rails.version >= '5.0'
  require 'rails-controller-testing'
  Rails::Controller::Testing.install
end

DA_ROOT = Pathname.new(File.expand_path("..", File.dirname(__FILE__)))

require DA_ROOT + File.join(%w{lib declarative_authorization authorization})
require DA_ROOT + File.join(%w{lib declarative_authorization in_controller})
require DA_ROOT + File.join(%w{lib declarative_authorization maintenance})

class MockDataObject
  def initialize(attrs = {})
    attrs.each do |key, value|
      instance_variable_set(:"@#{key}", value)
      self.class.class_eval do
        attr_reader key
      end
    end
  end

  def self.descends_from_active_record?
    true
  end

  def self.table_name
    name.tableize
  end

  def self.name
    "Mock"
  end

  def self.find(*args)
    raise StandardError, "Couldn't find #{self.name} with id #{args[0].inspect}" unless args[0]
    new :id => args[0]
  end

  def self.find_or_initialize_by(args)
    raise StandardError, "Syntax error: find_or_initialize by expects a hash: User.find_or_initialize_by(:id => @user.id)" unless args.is_a?(Hash)
    new :id => args[:id]
  end
end

class MockUser < MockDataObject
  def initialize(*roles)
    options = roles.last.is_a?(::Hash) ? roles.pop : {}
    super({:role_symbols => roles, :login => hash}.merge(options))
  end

  def initialize_copy(other)
    @role_symbols = @role_symbols.clone
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

class TestApp
  class Application < ::Rails::Application
    config.eager_load                 = false
    config.secret_key_base            = 'testingpurposesonly'
    config.active_support.deprecation = :stderr
    config.paths['config/database']   = File.expand_path('../database.yml', __FILE__)
    config.active_support.test_order  = :random
    initialize!
  end
end

class ApplicationController < ActionController::Base
end

Rails.application.routes.draw do
  match '/name/spaced_things(/:action)' => 'name/spaced_things', via: [:get, :post, :put, :patch, :delete]
  match '/deep/name_spaced/things(/:action)' => 'deep/name_spaced/things', via: [:get, :post, :put, :patch, :delete]
  match '/:controller(/:action(/:id))', via: [:get, :post, :put, :patch, :delete]
end

ActionController::Base.send :include, Authorization::AuthorizationInController

module Test
  module Unit
    class TestCase < Minitest::Test
      include Authorization::TestHelper
    end
  end
end

module ActiveSupport
  class TestCase
    include Authorization::TestHelper

    def request!(user, action, reader, params = {})
      action                           = action.to_sym if action.is_a?(String)
      @controller.current_user         = user
      @controller.authorization_engine = Authorization::Engine.new(reader)

      ((params.delete(:clear) || []) + [:@authorized]).each do |var|
        @controller.instance_variable_set(var, nil)
      end
      if Rails.version >= '5.0'
        get action, params: params
      else
        get action, params
      end
    end

    def setup
      @routes = Rails.application.routes
    end
  end
end
