$:.unshift(File.expand_path('../../lib', __FILE__))

require 'mandrill_queue'
require 'mandrill_queue/mailer'

require 'rspec'
require 'debugger'
require 'timecop'
require 'factory_girl'
require 'faker'

RSpec.configure do |config|
	config.order = 'random'
end
