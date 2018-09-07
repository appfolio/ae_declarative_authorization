require 'praxis'

class PraxisTestEngine < Rails::Engine
  initializer 'praxis_test_engine.add_middleware' do |app|
    root_path = PraxisTestEngine.root + 'test/praxis_dummy'
    mware = ::Praxis::MiddlewareApp.for(root: root_path)
    app.middleware.use mware
  end
end
