# frozen_string_literal: true

case RUBY_VERSION
when '3.2.5', '3.3.6', '3.4.1'
  ['7.0', '7.1', '7.2'].product(['1.6', '1.7', '1.8', '2.0', '2.1', '2.2']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
        gem 'sqlite3', '~> 1.4'
      end
    end
  end
  ['8.0'].product(['1.6', '1.7', '1.8', '2.0', '2.1', '2.2']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
        gem 'sqlite3', '~> 2.1'
      end
    end
  end
else
  raise "Unsupported Ruby version #{RUBY_VERSION}"
end
