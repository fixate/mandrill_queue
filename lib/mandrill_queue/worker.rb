require 'mandrill_queue/mailer'
require 'mandrill_queue/worker/hooks'
require 'mandrill_queue/mandrill_api'
require 'mandrill_queue/logging'

module MandrillQueue
	class Worker
		include MandrillApi
		extend Logging
		extend Hooks

		def ip_pool
			"Default Pool"
		end

		def perform(data)
			@_mailer = Mailer.new(data)
			self.class.logging.debug("Got mailer data: #{self.class.pretty(@_mailer.to_hash)}")

			message = @_mailer.message.load_attachments!.to_hash
			template = @_mailer.template
			send_at = @_mailer.send_at

			if template.nil?
				mandrill.messages.send(message, false, ip_pool, send_at)
			else
				content = @_mailer.content.to_key_value_array
				mandrill.messages.send_template(template, content, message, ip_pool, send_at)
			end
		end

		def self.perform(*args)
			result = new.perform(*args)
		rescue Mandrill::Error => e
			logging.error("A mandrill error occurred: #{e.class} - #{e.message}")
			raise
		else
			if !result.empty?
				log_results(result)
			else
				logging.error("No messages sent!")
			end
		end

	end
end
