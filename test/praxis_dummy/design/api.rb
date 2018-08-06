# frozen_string_literal: true

Praxis::ApiDefinition.define do |api|
  api.info do
    name 'praxis_dummy'
    title 'praxis_dummy'
    base_path '/praxis_test_engine'
    consumes 'json'
    produces 'json'
  end
end
