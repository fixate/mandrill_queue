require 'mandrill_queue/railtie' if defined?(Rails)
require 'mandrill_queue/core_ext'
require 'mandrill_queue/configuration'
require 'mandrill_queue/mailer'

module MandrillQueue
	def self.configuration
		@configuration ||= Configuration.new(defaults)
	end

	def self.configure
		yield configuration
		self
	end

	def self.defaults
		{
			message_defaults: {}
		}
	end

	def self.resque
		configuration.resque || ::Resque
	end

	# TODO: Support worker adapters
	# def self.load_adapter(adapter)
	#   require "mandrill_queue/adapters/#{adapter}"
	#   "#{adapter.camelize}Adapter".constantize.new
	# end

	# def self.adapter
	#   @_adapter ||= begin
	#     unless adapter = configuration.adapter
	#       adapter = :resque if defined(::Resque)
	#       adapter = :sidekiq if defined(::Sidekiq)
	#       if adapter.nil?
	#         raise RuntimeError, <<-TXT.strip.tr("\t", '')
	#           Worker adapter was not configured and cannot be determined.
	#           Please include a worker gem in your Gemfile. Resque and Sidekiq are supported.
	#         TXT
	#       end
	#     end
	#     load_adapter(adapter)
	#   end
	# end

	def self.reset_config(&block)
		@configuration = nil
		configure(&block) if block_given?
	end
end
