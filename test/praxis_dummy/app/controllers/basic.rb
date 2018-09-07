

module PraxisDummy
  module Controllers
    class Basic
      include Praxis::Controller
      include Authorization::AuthorizationInPraxisController

      implements PraxisDummy::Endpoints::Basic
      attr_accessor :current_user
      attr_writer :authorization_engine

      filter_access_to :test_action, :require => :test, :context => :permissions
      filter_access_to :test_action_2, :require => :test, :context => :permissions_2
      filter_access_to :show_stuff
      filter_access_to :edit_stuff, :create, :require => :test, :context => :permissions
      filter_access_to :edit, :require => :test, :context => :permissions,
                       :attribute_check => true, :model => PraxisDummy::Models::MockModel
      filter_access_to :new, :require => :test, :context => :permissions

      filter_access_to [:action_group_action_1, :action_group_action_2]

      def action_group_action_2
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json' })
      end

      def test_action
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def show_stuff
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def create
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def unprotected_action
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def new
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end

      def edit
        Praxis::Responses::Ok.new(headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
