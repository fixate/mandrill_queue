require 'pp'
require 'stringio'

module MandrillQueue
	module Logging
		def logging
			@_logger ||= MandrillQueue.configuration.logger || begin
			MandrillQueue.resque.constants.include?(:Logging) ? MandrillQueue.resque::Logging : nil
			end
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

			logging.debug <<-TXT.tr("\t", '')
				\n*******************************************
			#{formatted.join("\n")}
				*******************************************
			TXT

			if errors.empty?
				logging.info("#{result.count} message(s) successfully sent.")
			else
				logging.error("The following messages were not sent:\n#{errors.join("\n")}")
			end
		end
	end
end
