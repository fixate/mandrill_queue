require 'mandrill_queue/errors'
require 'mandrill_queue/message/recipient/helpers'

module MandrillQueue
	module Message
		class Recipients
			# Define DSL for inclusion in remote classes
			module DSL
				def recipients
					@_recipients ||= Recipients.new
				end

				def self.include_as(base, name)
					base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
				def #{name}(email = nil, name = nil, name_field = nil, &block)
					recipients.dsl(email, name, name_field, :#{name}, &block) if !email.nil? || block_given?
					block_given? ? self : recipients
				end
					RUBY
				end

				def self.included(base)
					[:to, :cc, :bcc].each do |x|
						include_as(base, x)
					end
				end
			end

			class Recipient
				ACCESSORS = [:type, :name, :email]

				def initialize(email = nil, name = nil, type = nil, &block)
					@type = type
					@name = name
					@email = email

					instance_eval(&block) if block_given?
				end

				ACCESSORS.each do |key|
					define_method key do |*args|
						var_sym = "@#{key}".to_sym
						if args.count > 0
							instance_variable_set(var_sym, args.first)
							args.first
						else
							instance_variable_get(var_sym)
						end
					end
				end

				def set!(hash)
					ACCESSORS.each do |key|
						instance_variable_set("@#{key}".to_sym, hash[key])
					end

					self
				end

				def to_hash(options = {})
					hash = {}
					ACCESSORS.each do |key|
						value = send(key)
						if options[:include_nils] || !value.nil?
							hash[key] = value.nil? ? nil : value.to_s
						end
					end
					hash
				end

				def validate(errors)
					errors.push([@type, "Email must be set for recipient."]) if email.nil?
				end

				alias_method :dsl, :instance_exec
			end

			def initialize
				@_recipients = []
			end

			def recipients
				@_recipients
			end

			def empty?
				@_recipients.empty?
			end

			def add(email = nil, name = nil, name_field = nil, type = nil, &block)
				if email.respond_to?(:each)
					add_objects(email, name, name_field, type, &block)
				elsif !email.is_a?(String)
					add_objects([email], name, name_field, type, &block)
				else
					@_recipients << Recipient.new(email, name, type, &block)
				end
			end

			alias_method :dsl, :add

			def to_a(options = {})
				@_recipients.map do |r|
					r.to_hash(options)
				end
			end

			def first
				@_recipients.first
			end

			def last
				@_recipients.last
			end

			def [](index)
				@_recipients[index]
			end

			def set!(value, type = nil)
				value = [value] unless value.is_a?(Array)

				@_recipients = value.map do |recipient|
					obj = Recipient.new

					case recipient
					when String
						obj.email recipient
						raise MessageError, "Must specify a recipient type when calling set! with a string on recipient." if type.nil?
						obj.type type unless type.nil?
					when Hash
						recipient.symbolize_keys!
						raise MessageError, "#{recipient} must contain email address" if recipient[:email].nil?
						obj.set!(recipient)
						obj.type type if obj.type.nil? && !type.nil?
					else
						raise MessageError, "#{recipient} is an invalid recipient."
					end

					obj
				end

				self
			end

			def validate(errors)
				@_recipients.each do |r|
					r.validate(errors)
				end
			end

			protected

			def add_object(obj, email_field = :email, name_field = nil, type = nil, &block)
				args.first = [args.first]
				add_objects(*args, &block)
			end

			def add_objects(list, email_field = :email, name_field = nil, type = nil, &block)
				if block_given?
					list.each do |r|
						obj = Recipient.new
						obj.dsl(r, &block)
						obj.type(type)
						@_recipients << obj
					end
				else
					hashes = MandrillQueue::Message::Recipient::Helpers
					.objects_to_hashes(list, [email_field, name_field].compact)

					@_recipients += hashes.map do |h|
						Recipient.new(h[email_field], h[name_field], type, &block)
					end
				end
			end

		end
	end
end
