# frozen_string_literal: true

require 'praxis/plugins/praxis_mapper_plugin'

Praxis::Application.configure do |application|
  # Use Rack::ContentLength middleware
  application.middleware Rack::ContentLength

  application.bootloader.use Praxis::Plugins::PraxisMapperPlugin,
                             config_data: {
                               repositories: {},
                               log_stats: 'skip'
                             }

  # Ensure we validate responses
  application.config.praxis.validate_responses = true #if %w[development test].include?(ENV['RAILS_ENV'])

  # Configure application layout
  application.layout do
    map :design, 'design/' do
      map :api, 'api.rb'
      map :endpoints, '**/endpoints/**/*'
    end
    map :app, 'app/' do
      map :models, '**/models/**/*'
      map :controllers, '**/controllers/**/*'
    end
  end
end

Praxis::Blueprint.caching_enabled = false
