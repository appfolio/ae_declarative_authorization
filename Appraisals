RAILS_VERSIONS = ['5.2.6', '6.0.2.1']
GRAPE_VERSIONS = ['1.1.0', '1.2.3', '1.3.0']

case RUBY_VERSION

when '2.5.3', '2.6.6', '2.7.2' then
  RAILS_VERSIONS.product(GRAPE_VERSIONS).each do |rails_version, grape_version|
    appraise "ruby-#{RUBY_VERSION}-rails#{rails_version}-grape#{grape_version}" do
      gem 'rails', rails_version
      gem 'grape', grape_version

      if Gem::Version.new(grape_version) < Gem::Version.new('1.3.0')
        # https://github.com/ruby-grape/grape/pull/1956
        gem "rack", "< 2.1.0"
      end

      if Gem::Version.new(rails_version) >= Gem::Version.new('6')
        gem 'sqlite3', '~> 1.4'
      else
        gem 'sqlite3', '~> 1.3.0'
      end
    end
  end
else
  raise "Unsupported Ruby version #{RUBY_VERSION}"

end
