

module PraxisDummy
  module Controllers
    class All
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::All
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :all
      filter_access_to :view, :require => :test, :context => :permissions

      def show
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json' })
      end

      def view
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
