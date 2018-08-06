# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class LoadMethod
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :show do
        description 'Load Method Show Action'
        routing {get '/show'}
        params do
          attribute :id, Integer#, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :show_id_not_required do
        description 'Load Method Show Action'
        routing {get '/show_id_not_required'}
        params do
          attribute :id, Integer
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :edit do
        description 'Load Method Edit Action'
        routing {get '/edit'}
        params do
          attribute :id, Integer, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :view do
        description 'Load Method View Action'
        routing {get '/view'}
        params do
          attribute :id, Integer#, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :update do
        description 'Load Method Update Action'
        routing {get '/update'}
        # params do
        #   attribute :id, Integer#, required: true
        # end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :delete do
        description 'Load Method Delete Action'
        routing {get '/delete'}
        params do
          attribute :id, Integer#, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :create do
        description 'Load Method Create Action'
        routing {get '/create'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
