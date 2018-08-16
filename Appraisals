case RUBY_VERSION

when '2.3.3' then

  appraise 'rails4252' do
    gem 'rails', '4.2.5.2'
  end

  appraise 'rails4271' do
    gem 'rails', '4.2.7.1'
  end

  appraise 'rails507' do
    gem 'rails', '5.0.7'
    gem 'rails-controller-testing'
  end

  appraise 'rails521' do
    gem 'rails', '5.2.1'
    gem 'rails-controller-testing'
  end

else
  raise "Unsupported Ruby version #{RUBY_VERSION}"

end
