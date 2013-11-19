module MandrillQueue
	module Message
		module Recipient
			class Variable
				class << self
					attr_reader :var_name

					def variables(name)
						@var_name = name
						Variables::DSL.include_as(self, name)
					end
				end

				def initialize(recipient = nil, *args, &block)
					@_recipient = recipient
					dsl(&block) if block_given?
				end

				def var_name
					self.class.var_name
				end

				def recipient=(value)
					@_recipient = value
				end

				def recipient(value = nil)
					@_recipient = value unless value.nil?
					@_recipient
				end

				def var_instance
					instance_variable_get("@_#{var_name}".to_sym)
				end

				def variables
					send(var_name)
				end

				def var_instance_set(value)
					instance_variable_set("@_#{var_name}".to_sym, value)
				end

				def to_hash(options = {})
					hash = {}
					hash[:rcpt] = recipient if options[:include_nils] || !recipient.nil?
					if options[:include_nils] || var_instance
						hash[var_name] = send(var_name).to_key_value_array(options)
					end
					hash
				end

				def set!(hash)
					@_recipient = hash[:rcpt]
					var_instance_set(nil)
					send(var_name).set!(hash[var_name]) unless hash[var_name].nil?
					self
				end

				def dsl(&block)
					send(var_name).dsl(&block)
				end

				def validate(errors, options = {})
					cn = options[:as] || self.class.name.underscore.split('/').last.to_sym
					errors.push([cn, "Recipient cannot be empty."]) if recipient.blank?
				end
			end

		end
	end
end
