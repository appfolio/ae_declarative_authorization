# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'declarative_authorization/version'

Gem::Specification.new do |s|
  s.name        = 'ae_declarative_authorization'
  s.version     = DeclarativeAuthorization::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['AppFolio', 'Steffen Bartsch']
  s.email       = 'dev@appfolio.com'
  s.description = 'ae_declarative_authorization is a Rails gem for maintainable authorization based on readable authorization rules.'
  s.summary     = s.description
  s.homepage    = 'http://github.com/appfolio/ae_declarative_authorization'
  s.licenses    = ['MIT']

  s.files         = Dir['**/*']
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency(%q<blockenspiel>, ['~> 0.5.0'])
  s.add_dependency(%q<rails>, ['>= 4.2.5.2', '< 5.1'])
  s.add_dependency('rails-controller-testing')
  s.add_dependency('pry')
end
