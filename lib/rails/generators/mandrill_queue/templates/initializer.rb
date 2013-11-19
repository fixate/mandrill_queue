MandrillQueue.configure do |config|
	# Your Mandrill API key
	# Only needed for the worker, so leave out if you run your worker
	# externally to Rails.
	# config.api_key = 'xxxxxx'

	# Message defaults.
	# A hash of application-wide default values for messages.
	# These can be overriden by class level defaults and by method
	# level defaults.
	# e.g.
	# {
	#		from_email: 'no-reply@example.com',
	#		preserve_recipients: false,
	#		global_merge_vars: {
	#			application_name: 'My super app!'
	#		}
	# }
	# config.message_defaults = {}

	# MandrillQueue will call enqueue on this instead of Resque
	# config.resque = MyOwnResque

	# Allows you to use your own worker for processing the mandrill
	# queue. This can be overriden at the class level.
	# config.default_worker_class = MyWorker

	# Allows you to override the queue name used to enqueue
	# to resque. This can be overriden at the class level
	# Defaults to :mailer
	# config.default_queue = :another_queue

	# Used to set the current logger. This can be any object
	# that responds to debug, info, warn, error and fatal
	# config.logger = MyLoggingClass
end
