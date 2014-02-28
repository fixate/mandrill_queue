require 'coveralls'
Coveralls.wear!

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'mandrill_queue'
require 'mandrill_queue/mailer'

require 'rspec'
require 'timecop'
require 'factory_girl'
require 'faker'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.extend TimecopHelpers

  config.order = 'random'
end
