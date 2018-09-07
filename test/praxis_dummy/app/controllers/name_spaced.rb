

module PraxisDummy
  module Controllers
    class NameSpaced
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::NameSpaced
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :show
      filter_access_to :update, :context => :name_spaced

      def show
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json' })
      end

      def update
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
