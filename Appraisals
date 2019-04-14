case RUBY_VERSION

when '2.3.3', '2.5.3', '2.6.2' then

  appraise "ruby-#{RUBY_VERSION}-rails507" do
    gem 'rails', '5.0.7'
    gem 'grape', '1.1.0'
    gem 'rails-controller-testing'
  end

  appraise "ruby-#{RUBY_VERSION}-rails516" do
    gem 'rails', '5.1.6'
    gem 'grape', '1.2.3'
    gem 'rails-controller-testing'
  end

  appraise "ruby-#{RUBY_VERSION}-rails521" do
    gem 'rails', '5.2.1'
    gem 'grape', '1.2.3'
    gem 'rails-controller-testing'
  end

  appraise "ruby-#{RUBY_VERSION}-rails522" do
    gem 'rails', '5.2.2'
    gem 'grape', '1.2.3'
    gem 'rails-controller-testing'
  end

else
  raise "Unsupported Ruby version #{RUBY_VERSION}"

end
