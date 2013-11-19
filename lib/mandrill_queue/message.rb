require 'mandrill_queue/worker'
require 'mandrill_queue/variables'
require 'mandrill_queue/errors'
require 'mandrill_queue/message/recipients'
require 'mandrill_queue/message/recipient/metadata'
require 'mandrill_queue/message/merge_vars'
require 'mandrill_queue/message/attachments'
require 'mandrill_queue/message/images'

module MandrillQueue
	module Message
		class Internal
			Variables::DSL.include_as(self, :global_merge_vars)
			Variables::DSL.include_as(self, :metadata)

			include Recipients::DSL
			include MergeVars::DSL
			include RecipientMetadata::DSL
			include Attachments::DSL
			include Images::DSL

			ACCESSORS = [
				:html, :text, :from_email, :from_name, :subject,
				:headers, :important, :track_opens, :track_clicks, :auto_text, :auto_html,
				:inline_css, :url_strip_qs, :preserve_recipients, :view_content_link,
				:bcc_address, :tracking_domain, :signing_domain, :return_path_domain,
				:merge, :tags, :subaccount, :google_analytics_domain,
				:google_analytics_campaign
			]

			EXTERNAL_ACCESSORS = [
				:global_merge_vars, :merge_vars, :recipient_metadata,
				:metadata, :attachments, :images
			]

			def initialize(values = nil)
				set!(values) unless values.nil?
			end

			ACCESSORS.each do |method|
				define_method method do |*args|
					var_sym = "@#{method}".to_sym
					if args.count > 0
						instance_variable_set(var_sym, args.first)
						args.first
					else
						instance_variable_get(var_sym)
					end
				end
			end

			alias_method :dsl, :instance_eval

			def nillify!
				transform_accessors! { |k| nil }

				EXTERNAL_ACCESSORS.each do |key|
					instance_variable_set("@_#{key}", nil)
				end

				@_recipients = nil
				self
			end

			def set!(values)
				nillify!
				values.symbolize_keys!
				transform_accessors! { |k| values[k] }

				EXTERNAL_ACCESSORS.each do |key|
					send(key).set!(values[key]) unless values[key].nil?
				end

				[:to, :cc, :bcc].each do |key|
					recipients.set!(values[key], key) if values[key]
				end
			end

			def content_message?
				!html.blank? || !text.blank?
			end

			def validate(errors)
				errors.push([:message, "Please specify at least one recipient."]) if to.empty?

				EXTERNAL_ACCESSORS.each do |key|
					sym = "@_#{key}"
					val = instance_variable_get(sym)
					val.validate(errors) unless val.nil? || !val.respond_to?(:validate)
				end

				recipients.validate(errors)
			end

			def load_attachments!
				@_attachments.load_all unless @_attachments.nil?
				@_images.load_all unless @_images.nil?
				self
			end

			def to_json(options = {})
				to_hash(options).to_json
			end

			def to_hash(options = {})
				hash = {}
				hash[:to] = recipients.to_a(options) if @_recipients

				ACCESSORS.each do |key|
					value = instance_variable_get("@#{key}")
					next if value.nil? && !options[:include_nils]
					hash[key] = value.respond_to?(:to_hash) ? value.to_hash : value
				end

				EXTERNAL_ACCESSORS.each do |key|
					sym = "@_#{key}".to_sym
					var = instance_variable_get(sym)
					if options[:include_nils] || !var.nil?
						if var.is_a?(Variables::Internal)
							hash[key] = var.to_key_value_array(options)
						else
							hash[key] = (var.to_hash(options) rescue var.to_a(options) rescue var)
						end
					end
				end

				hash
			end

			protected

			def transform_accessors!
				ACCESSORS.each do |key|
					sym = "@#{key}".to_sym
					instance_variable_set(sym, yield(key))
				end
			end
		end
	end
end
