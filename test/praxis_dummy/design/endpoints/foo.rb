# frozen_string_literal: true

module Endpoints
  class Foo
    include Praxis::ResourceDefinition
    version '1'

    media_type 'application/json'

    action :show do
      description 'Show me the Foo'
      routing {get '/:id'}
      params do
        attribute :id, required: true
      end
      response :ok
      response :unauthorized
    end

    action :action_group_action_2 do
      description 'action_group_action_2'
      routing {get '/action_group_action_2'}
      response :ok
      response :unauthorized
    end
  end
end
