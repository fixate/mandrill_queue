module MandrillQueue
	class Configuration
		ACCESSORS = [:message_defaults, :resque, :default_worker_class,
							 :default_queue, :api_key, :logger, :adapter, :adapter_options]
		attr_accessor(*ACCESSORS)

		def initialize(defaults = {}, &block)
			set(defaults)
			instance_eval(&block) if block_given?
		end

		def []=(key, value)
			send("#{key}=", value)
		end

		def [](key)
			send(key)
		end

		def reset
			ACCESSORS.each do |key|
				send("#{key}=", nil)
			end

			yield self if block_given?
		end

		def each_key(&block)
			ACCESSORS.each(&block)
		end

		def set(hash)
			each_key do |k, v|
				send("#{k}=", hash[k])
			end
		end

		def self.accessors
			ACCESSORS
		end
	end
end
