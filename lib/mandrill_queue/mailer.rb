require 'mandrill_queue'
require 'mandrill_queue/errors'
require 'mandrill_queue/message'
require 'mandrill_queue/variables'

module MandrillQueue
	class Mailer
		class << self
			def respond_to?(method, include_private = false)
				super || action_methods.include?(method)
			end

			def action_methods
				klass = self
				klass = klass.superclass until klass == MandrillQueue::Mailer
				return [] if self == klass
				self.public_instance_methods(true) -
					klass.public_instance_methods(true)
			end

			def method_missing(method, *args)
				if respond_to?(method)
					mailer = new(defaults)
					mailer.send(method, *args)
					mailer.template(template_from_method(method)) if mailer.template.blank? &&
						!mailer.message.content_message?
					mailer
				else
					super
				end
			end

			def configuration
				MandrillQueue.configuration
			end

			def defaults(&block)
				return @_defaults ||= {} unless block_given?

				mailer = new
				@_in_defaults = true
				mailer.instance_eval(&block)
				@_defaults = mailer.to_hash
			ensure
				@_in_defaults = false
			end

			def defaults=(hash)
				@_defaults = hash
			end

			def message_defaults
				md = configuration.message_defaults || {}
				md.merge!(defaults[:message]) unless @_in_defaults || defaults[:message].nil?
				md
			end

			def template_prefix(*args)
				@template_prefix = args.first unless args.count == 0
				if @template_prefix.nil?
					"#{self.name.chomp('Mailer').sluggify}-"
				else
					@template_prefix
				end
			end

			def all_templates
				action_methods.map do |method|
					template_from_method(method)
				end
			end

		private
			def template_from_method(method)
				template = defaults[:template].blank? ? method.to_s.sluggify : defaults[:template]
				template_prefix + template
			end
		end # End Singleton

		ACCESSORS = [:template, :send_at]

		def initialize(values = nil)
			set!(values) unless values.nil?
      @_adapter_options = self.class.configuration.adapter_options || {}
		end

		def reset!
			ACCESSORS.each do |key|
				instance_variable_set("@#{key}", nil)
			end
			@_message = nil
			@_content = nil
			self
		end

		def message(&block)
			@_message ||= Message::Internal.new(self.class.message_defaults)
			@_message.dsl(&block) if block_given?
			block_given? ? self : @_message
		end

		# Define setters
		ACCESSORS.each do |key|
			define_method key do |value = nil|
				var = "@#{key}".to_sym
				if value.nil?
					instance_variable_get(var)
				else
					instance_variable_set(var, value)
					self
				end
			end
		end

		alias :send_in :send_at

		def worker_class
			self.class.configuration.default_worker_class || ::MandrillQueue::Worker
		end

		def queue
			@_queue ||= \

			if instance_variable_defined?(:@queue)
				instance_variable_get(:@queue)
			elsif worker_class.instance_variable_defined?(:@queue)
				worker_class.instance_variable_get(:@queue)
			elsif worker_class.respond_to?(:queue)
				worker_class.queue
			else
				self.class.configuration.default_queue || :mailer
			end
		end

		def deliver(options = {})
			validate!
      MandrillQueue.adapter.enqueue_to(queue, worker_class, adapter_options.merge(options), to_hash)
		end

    def adapter_options(options = nil)
      @_adapter_options.merge!(options) unless options.nil?
      @_adapter_options ||= {}
    end

		def to_hash(options = {})
			hash = {}
			ACCESSORS.each do |key|
				value = instance_variable_get("@#{key}".to_sym)
				hash[key] = value if options[:include_nil] || !value.nil?
			end

			hash[:message] = message.to_hash(options) rescue nil if !@_message.nil? || options[:include_nils]
			hash[:content] = content.to_key_value_array(options) rescue nil if !@_content.nil? || options[:include_nils]
      hash
		end

		def set!(hash)
			hash.symbolize_keys!
			ACCESSORS.each do |key|
				instance_variable_set("@#{key}", hash[key])
			end

			message.set!(hash[:message]) unless hash[:message].nil?
			content.set!(hash[:content]) unless hash[:content].nil?
			self
		end

		alias_method :dsl, :instance_eval

		def use_defaults!
			set!(self.class.defaults) unless self.class.defaults.nil?
			self
		end

		def validate!
			errors = []
			message.validate(errors) unless @_message.nil?

			raise MandrillValidationError.new(errors) unless errors.empty?
			self
		end

		# Include variable DSL at end of class
		Variables::DSL.include_as(self, :content)
	end
end

if defined?(ActiveSupport)
	ActiveSupport.run_load_hooks(:mandrill_queue, MandrillQueue::Mailer)
end
