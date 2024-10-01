# frozen_string_literal: true

case RUBY_VERSION
when '3.1.3', '3.2.1', '3.3.0'
  ['6.1', '7.0', '7.1', '7.2'].product(['1.6', '1.7', '1.8']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
      end
    end
  end
else
  raise "Unsupported Ruby version #{RUBY_VERSION}"
end
