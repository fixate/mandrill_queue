$:.unshift(File.expand_path('../', __FILE__))
# Generated by MandrillQueue gem
# Use this to have a light weight resque worker (no rails environment)
# which can be run as follows:
# QUEUES=mailer rake resque:work -r ./worker.rb

require 'bundler/setup'

require 'resque'
require 'resque/tasks'
require 'mono_logger' # or log4r or rails logger

# Require the class that actually does the work
require 'mandrill_queue/worker'

# You can load your rails initializer here:
# require 'config/initializer/mandrill_queue.rb
# or configure only what you need for the worker:
MandrillQueue.configure do |config|
	config.api_key = ''# TODO: Mandrill api key

	config.logger = MonoLogger.new(STDOUT) # or log4r or Logger or ...
end
