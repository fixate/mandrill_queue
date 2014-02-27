require 'pp'
require 'stringio'

module MandrillQueue
	module Logging
		def logger
			MandrillQueue.configuration.logger
		end

		def pretty(obj)
			s = StringIO.new
			PP.pp(obj, s)
			s.rewind
			s.read
		end

		def result_formatter(r)
			<<-TXT
				ID: #{r['_id']}
				EMAIL: #{r['email']}
				STATUS: #{r['status']}
				---
				TXT
		end

		def log_results(result)
			errors = []
			formatted = result.map do |r|
				unless ['sent', 'queued'].include?(r['status'])
					errors << result_formatter(r)
				end

				result_formatter(r)
			end

			logger.debug <<-TXT.tr("\t", '')
				\n*******************************************
			#{formatted.join("\n")}
				*******************************************
			TXT

			if errors.empty?
				logger.info("#{result.count} message(s) successfully sent.")
			else
				logger.error("The following messages were not sent:\n#{errors.join("\n")}")
			end
		end
	end
end
