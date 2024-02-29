# frozen_string_literal: true

require_relative 'lib/declarative_authorization/version'

Gem::Specification.new do |spec|
  spec.name          = 'ae_declarative_authorization'
  spec.version       = DeclarativeAuthorization::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.author        = 'AppFolio'
  spec.email         = 'opensource@appfolio.com'
  spec.description   = 'Rails gem for maintainable authorization based on readable authorization rules.'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/appfolio/ae_declarative_authorization'
  spec.license       = 'MIT'
  spec.files         = Dir['**/*'].select { |f| f[%r{^(lib/|LICENSE.txt|.*gemspec)}] }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('< 3.4')
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_dependency('blockenspiel', ['>= 0.5', '< 1'])
  spec.add_dependency('rails', ['>= 6.1', '< 7.2'])
end
