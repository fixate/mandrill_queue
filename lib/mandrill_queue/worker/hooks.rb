require 'pp'
require 'stringio'
require 'mandrill_queue/logging'

module MandrillQueue
	module Hooks
		extend Logging

		def on_failure_logging(error, message)
			s = StringIO.new
			PP.pp(message, s)
			s.rewind
			logging.error <<-TXT.strip
			#{'=' * 50}
			An exception has occurred for the following message:\n#{pretty(message)}
			TXT
			logging.error(error)
			logging.error('=' * 50)
		end
	end
end
