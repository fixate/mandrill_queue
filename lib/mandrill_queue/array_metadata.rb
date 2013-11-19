module MandrillQueue
	class ArrayMetadata
		class Var
			Variables::DSL.include_as(self, :vars)

			def initialize(recipient = nil, &block)
				@_recipient = recipient
				dsl(&block) if block_given?
			end

			def recipient=(value)
				@_recipient = value
			end

			def recipient(value = nil)
				@_recipient = value unless value.nil?
				@_recipient
			end

			def to_hash(options = {})
				hash = {}
				hash[:rcpt] = recipient if options[:include_nils] || !recipient.nil?
				hash[:vars] = vars.to_key_value_array(options) if options[:include_nils] || !@_vars.nil?
				hash
			end

			def set!(hash)
				@_recipient = hash[:rcpt]
				@_vars = nil
				vars.set!(hash[:vars]) unless hash[:vars].nil?
				self
			end

			def dsl(&block)
				vars.dsl(&block)
			end

			def validate(errors)
				errors.push([:merge_vars, "Recipient cannot be empty for merge vars."]) if recipient.blank?
			end
		end

		module DSL
			def merge_vars(recipient = nil, &block)
				@_merge_vars ||= MergeVars.new
				@_merge_vars.dsl(recipient, &block) if !recipient.nil? || block_given?
				block_given? ? self : @_merge_vars
			end
		end

		def initialize
			@_merge_vars = []
		end

		def add(*args, &block)
			@_merge_vars << Var.new(*args, &block)
		end

		alias_method :dsl, :add

		def to_a(options = {})
			@_merge_vars.map do |v|
				v.to_hash(options)
			end
		end

		def first
			@_merge_vars.first
		end

		def last
			@_merge_vars.last
		end

		def [](index)
			@_merge_vars[index]
		end

		def count
			@_merge_vars.count
		end

		def merge_vars
			@_merge_vars
		end

		def validate(errors)
			@_merge_vars.each do |v|
				v.validate(errors)
			end
		end

		def set!(list)
			@_merge_vars = list.map do |obj|
				Var.new.set!(obj.symbolize_keys)
			end

			self
		end
	end

	end
end
