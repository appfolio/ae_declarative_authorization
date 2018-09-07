# frozen_string_literal: true

module PraxisDummy
  module Endpoints
    class Basic
      include Praxis::ResourceDefinition
      version '1'

      media_type 'application/json'

      action :index do
        description 'Index Test'
        routing {get '/'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :new do
        description 'New Test'
        routing {get '/new'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :edit do
        description 'Edit Test'
        routing {get '/edit'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :show_stuff do
        description 'Show Test'
        routing {get '/show_stuff/:id'}
        params do
          attribute :id, Integer, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :update do
        description 'Update Test'
        routing {put '/:id'}
        params do
          attribute :id, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :create do
        description 'Create Test'
        routing {post '/'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :destroy do
        description 'Destroy Test'
        routing {delete '/:id'}
        params do
          attribute :id, required: true
        end
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :test_action do
        description 'test_action'
        routing {get '/test_action'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :test_action_2 do
        description 'test_action_2'
        routing {get '/test_action_2'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :unprotected_action do
        description 'unprotected_action'
        routing {get '/unprotected_action'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :action_group_action_1 do
        description 'action_group_action_1'
        routing {get '/action_group_action_1'}
        response :ok
        response :unauthorized
        response :forbidden
      end

      action :action_group_action_2 do
        description 'action_group_action_2'
        routing {get '/action_group_action_2'}
        response :ok
        response :unauthorized
        response :forbidden
      end
    end
  end
end
