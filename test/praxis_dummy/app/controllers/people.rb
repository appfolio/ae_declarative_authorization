

module PraxisDummy
  module Controllers
    class People
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::People
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :all

      def show
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json' })
      end

      def view
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
