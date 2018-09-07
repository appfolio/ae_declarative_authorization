

module PraxisDummy
  module Controllers
    class Overwrite
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::Overwrite
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :test_action, :test_action_2, :require => :test, :context => :permissions_2
      filter_access_to :test_action, :require => :test, :context => :permissions

      def test_action
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json' })
      end

      def test_action_2
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
