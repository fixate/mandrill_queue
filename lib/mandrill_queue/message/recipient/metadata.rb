require 'mandrill_queue/errors'
require 'mandrill_queue/message/recipient/data'
require 'mandrill_queue/message/recipient/variable'

module MandrillQueue
	module Message
		class RecipientMetadata < Recipient::Data
			class Metadatum < Recipient::Variable
				variables :values
			end

			var_class Metadatum

			module DSL
				def recipient_metadata(*args, &block)
					@_recipient_metadata ||= RecipientMetadata.new
					@_recipient_metadata.dsl(*args, &block) if block_given? || args.count > 0
					block_given? ? self : @_recipient_metadata
				end
			end
		end
	end
end
