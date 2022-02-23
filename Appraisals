# frozen_string_literal: true

case RUBY_VERSION
when '2.6.9'
  ['6.0', '6.1'].product(['1.3', '1.4', '1.5', '1.6']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
      end
    end
  end
when '2.7.5'
  ['6.0', '6.1', '7.0'].product(['1.3', '1.4', '1.5', '1.6']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
      end
    end
  end
when '3.1.0'
  ['6.0', '6.1', '7.0'].product(['1.6']).each do |rails_version, grape_version|
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
