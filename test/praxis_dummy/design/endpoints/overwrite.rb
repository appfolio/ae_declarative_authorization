# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class Overwrite
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :test_action do
        description 'Overwrite test_action Action'
        routing {get '/test_action'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :test_action_2 do
        description 'Overwrite test_action_2 Action'
        routing {get '/test_action_2'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
