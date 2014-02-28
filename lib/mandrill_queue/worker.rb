require 'mandrill_queue/mailer'
require 'mandrill_queue/worker/hooks'
require 'mandrill_queue/mandrill_api'
require 'mandrill_queue/logging'

module MandrillQueue
	class Worker
		include MandrillApi
		include Logging
		extend Hooks
    include Sidekiq::Worker if defined?(Sidekiq)

		def ip_pool
			"Default Pool"
		end

		def perform(data)
			@_mailer = Mailer.new(data)
			logger.debug("Got mailer data: #{pretty(@_mailer.to_hash)}")

			message = @_mailer.message.load_attachments!.to_hash
			template = @_mailer.template
			send_at = @_mailer.send_at

			result = if template.nil?
				mandrill.messages.send(message, false, ip_pool, send_at)
			else
				content = @_mailer.content.to_key_value_array
				mandrill.messages.send_template(template, content, message, ip_pool, send_at)
			end
    rescue Mandrill::Error => e
      logger.error("A mandrill error occurred: #{e.class} - #{e.message}")
      raise
    else
      if result.nil?
        logger.error("No messages sent!")
      else
        log_results(result)
      end
		end

		def self.perform(*args)
			new.perform(*args)
		end

	end
end
