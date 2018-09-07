

module PraxisDummy
  module Controllers
    class LoadMethod
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::LoadMethod
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :show, :show_id_not_required, attribute_check: true, model: PraxisDummy::Models::MockModel
      filter_access_to :edit, attribute_check: true
      filter_access_to :update, :delete, attribute_check: true,
                       load_method: proc {PraxisDummy::Models::MockModel.new(test: 1)}
      filter_access_to :create do
        permitted_to! :edit, :praxis_dummy_controllers_load_method
      end
      filter_access_to :view, :attribute_check => true, load_method: :load_method

      def show(id:)
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def show_id_not_required(id: nil)
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def edit(id:)
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def update
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def delete(id:)
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def create
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def view(id: nil)
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
