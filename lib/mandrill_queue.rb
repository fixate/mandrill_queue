require 'mandrill_queue/railtie' if defined?(Rails)
require 'mandrill_queue/core_ext'
require 'mandrill_queue/errors'
require 'mandrill_queue/configuration'
require 'mandrill_queue/mailer'

module MandrillQueue
  @@lock = Mutex.new

	def self.configuration
		@configuration ||= Configuration.new(defaults)
	end

	def self.configure
		yield configuration
		self
	end

	def self.defaults
		{
			message_defaults: {},
      adapter: :resque
		}
	end

  def self.load_adapter(adapter)
    if adapter.is_a?(Symbol)
      require "mandrill_queue/adapters/#{adapter}_adapter"
      "MandrillQueue::Adapters::#{adapter.to_s.camelize}Adapter".constantize.new
    elsif adapter.is_a?(String)
      adapter.constantize.new
    else
      adapter.try(:call) || adapter
    end
  end

  def self.adapter
    @@lock.synchronize do
      @_adapter ||= begin
        unless adapter = configuration.adapter
          adapter = :resque if defined(::Resque)
          adapter = :sidekiq if defined(::Sidekiq)
          if adapter.nil?
            raise RuntimeError, <<-TXT.strip.tr("\t", '')
              Worker adapter was not configured and cannot be determined.
              Please include a worker gem in your Gemfile. Resque and Sidekiq are supported.
            TXT
          end
        end
        load_adapter(adapter)
      end
    end
  end

  def self.adapter=(adapter)
    @_adapter = adapter.nil? ? nil : load_adapter(adapter)
  end

  def self.eager_load!
    # No autoloads
  end

	def self.reset_config(&block)
    self.adapter = nil
		@configuration = nil
		configure(&block) if block_given?
	end
end
