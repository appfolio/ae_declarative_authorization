# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class All
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :show do
        description 'All Show Action'
        routing {get '/show'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :view do
        description 'All View Action'
        routing {get '/view'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
