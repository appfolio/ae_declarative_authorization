case RUBY_VERSION

when '2.3.3' then

  appraise "ruby-#{RUBY_VERSION}_rails4252" do
    gem 'rails', '4.2.5.2'
  end

  appraise "ruby-#{RUBY_VERSION}_rails4271" do
    gem 'rails', '4.2.7.1'
  end

  appraise "ruby-#{RUBY_VERSION}_rails504" do
    gem 'rails', '5.0.4'
    gem 'rails-controller-testing'
  end

else
  raise "Unsupported Ruby version #{RUBY_VERSION}"

end
