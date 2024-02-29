require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'debug'
require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'

ENV['RAILS_ENV'] = 'test'

require 'rails/all'
require 'test_support/minitest_compatibility'

DA_ROOT = Pathname.new(File.expand_path("..", File.dirname(__FILE__)))

require DA_ROOT + File.join(%w{lib declarative_authorization authorization})
require DA_ROOT + File.join(%w{lib declarative_authorization maintenance})
require DA_ROOT + File.join(%w{lib declarative_authorization test helpers})

Mocha.configure do |config|
  config.stubbing_non_existent_method = :prevent
  config.strict_keyword_argument_matching = true
end

Minitest::Test.make_my_diffs_pretty!
Minitest::Reporters.use! unless ENV['RM_INFO']

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
    new args
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

class User < ActiveRecord::Base
  attr_accessor :role_symbols

  scope :visible_by, ->(user) { where(id: user.id) }
end

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

      method = params.delete(:method) || :get

      send method, action, params: params
    end

    def setup
      @routes = Rails.application.routes
    end
  end
end

require 'test_support/rails'

begin
  require 'grape'
  require 'test_support/grape'
rescue LoadError
  # Grape is not defined in the gemspec so the Grape tests will not be run
end
