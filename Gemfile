source 'https://rubygems.org'

gemspec

group :test do
  gem 'rspec', require: false
  gem 'guard-rspec', require: false

  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  gem 'ruby_gntp' if RUBY_PLATFORM =~ /darwin/i
  gem 'libnotify' if RUBY_PLATFORM =~ /linux/i

  gem 'coveralls', require: false
end

platforms :rbx do
  gem 'racc'
  gem 'rubysl'
end

# group :development, :test do
#   gem 'debugger', platform: :ruby
# end
