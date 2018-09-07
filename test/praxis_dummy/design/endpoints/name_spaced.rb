# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class NameSpaced
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :show do
        description 'NameSpaced Show Action'
        routing {get '/show'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :update do
        description 'NameSpaced Update Action'
        routing {get '/update'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
