require 'base64'
require 'mime/types'

module MandrillQueue
	module Message
		class Attachments
			class Attachment
				ACCESSORS = [:file, :name, :content, :type]

				def initialize(file = nil, options = {}, &block)
					@options = options
					@file = file

					if file.is_a?(Hash)
						@options = file
						@file = nil
					end

					load_file if @options[:load_file] && !@file.nil?

					instance_eval(&block) if block_given?
				end

				def file(*args)
					if args.count > 0
						reset!
						@file = args.first
					end
					@file
				end

				def reset!
					@file = nil
					@type = nil
					@content = nil
					@name = nil
				end

				def file_loaded?
					!@content.nil?
				end

				def name(*args)
					@name = args.first if args.count > 0

					@name ||= (File.basename(@file) unless @file.nil?)
				end

				def type(*args)
					@type = args.first if args.count > 0

					@type ||= begin
						unless @file.nil?
							MIME::Types.type_for(@file).first.to_s
						end || "application/octet-stream"
					end
				end

				def content(*args)
					if args.count > 0
						@content = Base64.encode64(args.first)
					end
					@content
				end

				def content64(*args)
					@content = args.first if args.count > 0
					@content
				end

				def load_file
					return false if file_loaded?

					content(IO.read(@file))
					# set @name and @type if not already set before getting rid of file
					name()
					type()
					@file = nil
					self
				end

				def validate(errors, options = {})
					options[:as] ||= :attachments
					errors.push([options[:as], "No file or content for attachment '#{name}'."]) if content64.nil? && file.nil?
					errors.push([options[:as], "No attachment name given."]) if name.nil?
					errors.push([options[:as], "File to load (#{file}) does not exist."]) if @file && !file_loaded? && !File.exist?(file)
				end

				def set!(hash)
					ACCESSORS.each do |key|
						instance_variable_set("@#{key}", hash[key])
					end

					self
				end

				def to_hash(options = {})
					hash = {}

					ACCESSORS.each do |key|
						value = send(key)
						hash[key] = value if options[:include_nils] || !value.nil?
					end

					hash
				end

				alias_method :dsl, :instance_eval
			end

			module DSL
				def attachments(&block)
					@_attachments ||= Attachments.new
					@_attachments.dsl(&block) if block_given?
					block_given? ? self : @_attachments
				end
			end

			def initialize
				@_attachments = []
			end

			def add(*args, &block)
				@_attachments << attachment_class.new(*args, &block)
			end

			def attachment_class
				@_klass ||= Attachment
			end

			def count
				@_attachments.count
			end

			def load_all
				@_attachments.each(&:load_file)
			end

			def to_a(options = {})
				@_attachments.map do |a|
					a.to_hash(options)
				end
			end

			def set!(list)
				@_attachments = list.map do |obj|
					attachment_class.new.set!(obj.symbolize_keys)
				end

				self
			end

			def attachments
				@_attachments
			end

			def validate(errors, options = {})
				@_attachments.each do |a|
					a.validate(errors, options)
				end
			end

			alias_method :dsl, :instance_eval

			Variables::DSL.include_as(self, :vars)
		end
	end
end
