module MandrillQueue
	class Error < ::StandardError; end

	class MandrillValidationError < Error
		def initialize(errors)
			@_errors = errors
			super(message)
		end

		def message
			<<-TXT
			Validation Errors:
			#{@_errors.inject(''){ |s, (name, e)| s += "\n- [#{name}]: #{e}" }}
			TXT
		end
	end

	class MessageError < Error; end

	class VariableError < Error; end
	class VariableNotSetError < VariableError; end

	class RecipientDataError < Error; end
end
