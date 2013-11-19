require 'mandrill_queue/errors'
require 'mandrill_queue/variables'
require 'mandrill_queue/message/recipient/helpers'

module MandrillQueue
	module Message
		module Recipient
			class Data

				def self.inherited(base)
					base.class_eval do
						define_method(base.name.underscore.split('/').last) do
							@_vars
						end
					end
				end

				def self.var_class(klass = nil)
					@_var_class = klass unless klass.nil?
					@_var_class
				end

				def register_recipient(email, index)
					raise RecipientDataError, "#{email} has already been registered in recipient index." if recipient_index.has_key?(email)
					recipient_index[email] = index
				end

				def recipient_index
					@_rcpt_index || clear_recipient_index
				end

				def clear_recipient_index
					@_rcpt_index = {}
				end

				def initialize
					@_vars = []
				end

				def var_class
					self.class.var_class
				end

				def add(*args, &block)
					recipient = args.first
					if recipient.is_a?(String)
						ind = recipient_index[recipient]
						if ind.nil?
							@_vars << var_class.new(*args, &block)
							register_recipient(recipient, @_vars.count - 1)
						else
							self[ind].variables.dsl(&block)
						end
					elsif recipient.respond_to?(:each)
						add_objects(*args, &block)
					elsif !recipient.nil?
						raise MessageError, "Invalid recipient for #{name}"
					end
				end

				alias_method :dsl, :add

				def to_a(options = {})
					@_vars.map do |v|
						v.to_hash(options)
					end
				end

				def first
					@_vars.first
				end

				def last
					@_vars.last
				end

				def [](index)
					@_vars[index]
				end

				def count
					@_vars.count
				end

				def validate(errors)
					@_vars.each do |v|
						v.validate(errors)
					end
				end

				def set!(list)
					@_vars = list.map do |obj|
						var_class.new.set!(obj.symbolize_keys)
					end

					self
				end

			protected

				def add_objects(list, recipient_field = :email, fields = nil, &block)
					if recipient_field.is_a?(Array)
						fields, recipient_field = recipient_field, :email
					end

					if block_given?
						# if a block is given we want to hand the array over
						# to the block for mapping
						list.each do |obj|
							recipient = obj.send(recipient_field)
							ind = recipient_index[recipient]
							if ind.nil?
								var = var_class.new
								var.recipient = recipient
								var.variables.dsl(obj, &block)
								@_vars << var
								register_recipient(recipient, @_vars.count - 1)
							else
								self[ind].variables.dsl(obj, &block)
							end
						end
					else
						# Include recipient in final var hash if fields not specified
						# or if explicitly added in fields.
						includes_recipient = fields.nil? || fields.include?(recipient_field)

						fields << recipient_field unless fields.nil? || includes_recipient

						hashes = Helpers.objects_to_hashes(list, fields)

						hashes.each do |h|
							recipient = includes_recipient ? h[recipient_field] : h.delete(recipient_field)
							ind = recipient_index[recipient]
							if ind.nil?
								var = var_class.new
								var.recipient = recipient
								var.variables.set!(h)
								@_vars << var
								register_recipient(recipient, @_vars.count - 1)
							else
								self[ind].variables.merge!(h)
							end
						end
					end
				end
			end
		end
	end
end
