require 'mandrill'
require 'mandrill_queue'
require 'mandrill_queue/errors'

module MandrillQueue
	module MandrillApi
		def configuration
			MandrillQueue.configuration
		end

		def mandrill
			@_api ||= begin
				if configuration.api_key.nil?
					raise MandrillQueue::ConfigurationError, <<-ERR
					An Api key has not been configured. Please configure on as follows in an initializer:
					MandrillQueue.configure do { |c| c.api_key = 'xxxxxxxxxxxxxx' }
					ERR
				end

				Mandrill::API.new(configuration.api_key)
			end
		end
	end
end
