module MandrillQueue
	module Variables
		# Define DSL for inclusion in remote classes
		module DSL
			def self.include_as(base, name)
				base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
				def #{name}(values = nil, &block)
					@_#{name} ||= Variables::Internal.new
					@_#{name}.merge!(values) if values.is_a?(Hash)
					@_#{name}.dsl(&block) if block_given?
					block_given? ? self : @_#{name}
				end
				RUBY
			end

			def self.included(base)
				include_as(base, :variables)
			end
		end

		class Internal
			def initialize(values = nil, &block)
				@_variables = values if values.is_a?(Hash)
				@_variables ||= {}
				dsl(&block) if block_given?
			end

			alias_method :dsl, :instance_exec

			def respond_to?(method)
				super || @_variables.has_key?(method)
			end

			def to_hash(options = {})
				if options.has_key?(:include_nils) && options[:include_nils]
					@_variables
				else
					@_variables.reject { |k, v| v.nil? }
				end
			end

			def to_key_value_array(options = {})
				options[:name_key] ||= :name
				options[:content_key] ||= :content

				result = []
				@_variables.each do |k, v|
					if !v.nil? || options[:include_nils]
						result.push({options[:name_key] => k.to_s, options[:content_key] => v})
					end
				end unless @_variables.nil?
				result
			end

			def [](key)
				@_variables[key]
			end

			def []=(key, value)
				@_variables[key.to_sym] = value
			end

			def set!(hash, options = {})
				case hash
				when Hash
					@_variables = hash.symbolize_keys
				when Array
					options[:name_key] ||= :name
					options[:content_key] ||= :content
					@_variables = {}
					hash.dup.each do |obj|
						obj.symbolize_keys!
						@_variables[obj[options[:name_key]].to_sym] = obj[options[:content_key]]
					end
				end
				self
			end

			def merge!(hash)
				@_variables.merge!(hash)
			end

			def method_missing(method, *args, &block)
				if method.to_s.end_with?('=')
					method = method.to_s.chomp('=').to_sym
				end

				if args.count > 0
					@_variables[method] = args.first
					self
				else
					raise VariableNotSetError, "#{method} has not been set." \
						unless @_variables.has_key?(method)
					@_variables[method]
				end
			end
		end
	end
end
