require 'mocha/minitest'

class PraxisTestCase < Minitest::Test
  include Rack::Test::Methods

  APP = Rack::Builder.app do
    run Rails.application
  end

  def app
    APP
  end

  def request!(controller_class, user, url, reader, method: :get, **params)
    controller_class.any_instance.stubs(:current_user).returns(user)
    controller_class.any_instance.stubs(:authorization_engine).returns(Authorization::Engine.new(reader))
    send(method, url, params)
  end

  def response
    last_response
  end
end

