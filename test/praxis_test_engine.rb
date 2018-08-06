require 'praxis'

class PraxisTestEngine < Rails::Engine
  initializer 'praxis_test_engine.add_middleware' do |app|
    root_path = PraxisTestEngine.root + 'test/praxis_dummy'
    mware = Praxis::MiddlewareApp.for(root: root_path, name: 'app-praxis-test')
    app.middleware.use mware

    Rails.application.config.after_initialize do
      mware.setup
    end
  end
end
