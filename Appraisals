# frozen_string_literal: true

case RUBY_VERSION
when '3.2.5', '3.3.6', '3.4.1'
  ['7.2'].product(['1.6', '1.7', '1.8', '2.0', '2.1', '2.2']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}_sqlite1" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
        gem 'sqlite3', '~> 1.7'
      end
    end
  end
  ['8.0', '8.1'].product(['1.6', '1.7', '1.8', '2.0', '2.1', '2.2']).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails_#{rails_version}-grape_#{grape_version}_sqlite2" do
      source 'https://rubygems.org' do
        gem 'rails', "~> #{rails_version}.0"
        gem 'grape', "~> #{grape_version}.0"
        gem 'sqlite3', '~> 2.8'
      end
    end
  end
when '3.1.7'
      ['7.0', '7.1', '7.2'].product(['1.6']).each do |rails_version, grape_version|
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
