# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class People
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :show do
        description 'People Show Action'
        routing {get '/show'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
