appraise 'activerecord-5.0' do
  gem 'activerecord', '~> 5.0.1'
end

appraise 'activerecord-5.1' do
  gem 'activerecord', '~> 5.1.0'
end

appraise 'activerecord-5.2' do
  gem 'mysql2', '~> 0.4.4'

  git 'https://github.com/rails/rails.git' do
    gem 'activerecord', '>= 5.2.0.beta2', '< 6'
  end
end
