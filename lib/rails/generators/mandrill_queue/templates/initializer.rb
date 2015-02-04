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

  # Change to your prefered queue (adapter)
  # Adapters should respond to :enqueue_to
  # Valid values are:
  # * :resque (default)
  # * :sidekiq
  # * anything that responds to call, return value is used as the adapter
  # * Class name in string format (e.g. adapter sitting in lib/)
  # * Any object that responds to :enqueue_to with arity > 1
	# config.adapter = MyOwnQueuer

	# Allows you to use your own worker for processing the mandrill
	# queue. This can be overriden at the class level.
	# config.default_worker_class = MyWorker

	# Allows you to override the queue name used to enqueue
	# to the background queue. This can be overriden at the
  # class level.
	# Defaults to :mailer
	# config.default_queue = :another_queue

	# Used to set the current logger. This can be any object
	# that responds to debug, info, warn, error and fatal
	# config.logger = MyLoggingClass
  #
  # Default options passed through to the queue adapter
  # These options can mean different things depending on
  # which adapter you choose.
  # config.adapter_options = {}
end
