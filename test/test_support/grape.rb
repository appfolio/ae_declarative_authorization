require 'grape'
require 'mocha/minitest'

Mocha.configure do |config|
  config.stubbing_non_existent_method = :prevent
  config.strict_keyword_argument_matching = true
end

require DA_ROOT + File.join(%w{lib declarative_authorization controller grape})

class ApiTestCase < ActiveSupport::TestCase
  include Rack::Test::Methods
  include Authorization::TestHelper

  class << self
    attr_accessor :api
  end

  attr_accessor :last_endpoint

  def self.tests(api)
    @api = api
  end

  def app
    self.class.api
  end

  def request!(user, action, reader, params = {}, &block)
    Grape::Endpoint.before_each do |endpoint|
      self.last_endpoint = endpoint

      engine = Authorization::Engine.new(reader)
      endpoint.stubs(:current_user).returns(user)
      endpoint.stubs(:authorization_engine).returns(engine)

      ((params.delete(:clear) || []) + [:@authorized]).each do |var|
        endpoint.instance_variable_set(var, nil)
      end

      yield endpoint if block_given?
    end

    method = params.delete(:method) || :get
    send method, action #, params
  end
end

module MockAPI
  extend ActiveSupport::Concern

  included do
    include Authorization::Controller::Grape

    helpers do
      attr_accessor :authorized

      def authorization_engine
      end

      def current_user
      end

      def authorized?
        !!@authorized
      end
    end


    def self.define_action_methods(*methods)
      resource_name = name.to_param.underscore.gsub(/_api$/, '')
      resources resource_name do
        methods.each do |method|
          get method do
            @authorized = true
            'nothing'
          end
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
end

class MocksAPI < Grape::API
  include MockAPI
end

if Gem::Version.new(Grape::VERSION) >= Gem::Version.new('1.2.0')
  class MocksAPIInstance < Grape::API::Instance
    include MockAPI
  end
else
  class MocksAPIInstance < MocksAPI
  end
end

class ApplicationAPI < ActionController::Base
end
