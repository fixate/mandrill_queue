source 'https://rubygems.org'

gemspec

group :test do
  gem 'rspec', require: false
  gem 'guard-rspec', require: false
  gem 'timecop', require: false
  gem 'factory_girl', require: false
  gem 'faker', require: false

  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  gem 'ruby_gntp' if RUBY_PLATFORM =~ /darwin/i
  gem 'libnotify' if RUBY_PLATFORM =~ /linux/i
end

# group :development, :test do
#   gem 'debugger', platform: :ruby
# end
