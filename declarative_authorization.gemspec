# frozen_string_literal: true

require_relative 'lib/declarative_authorization/version'

Gem::Specification.new do |spec|
  spec.name          = 'ae_declarative_authorization'
  spec.version       = DeclarativeAuthorization::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.author        = 'AppFolio'
  spec.email         = 'opensource@appfolio.com'
  spec.description   = 'Provides an authorization mechanism for Rails applications inspired by role-based access control (RBAC). Authorization is defined through readable rules that map roles to permitted actions, making access control easier to maintain.'
  spec.summary       = 'Rails gem for maintainable authorization based on readable authorization rules.'
  spec.homepage      = 'https://github.com/appfolio/ae_declarative_authorization'
  spec.license       = 'MIT'
  spec.files         = Dir['**/*'].select { |f| f[%r{^(lib/|LICENSE.txt|declarative_authorization\.gemspec|README.md|rubocop-decl-auth.yml)}] }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('< 4.1')
  spec.metadata['allowed_push_host'] = 'https://appfolio.jfrog.io/artifactory/api/gems/appfolio-ae_declarative_authorization-gem/'

  spec.add_dependency('blockenspiel', ['>= 0.5', '< 1'])
  spec.add_dependency('rails', ['>= 7.2', '< 8.2'])
end
