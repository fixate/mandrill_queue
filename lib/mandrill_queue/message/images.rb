require 'mime/types'
require 'mandrill_queue/message/attachments'

module MandrillQueue
	module Message
		class Images < Attachments
			class Image < Attachments::Attachment
				def image_type?
					MIME::Types[/^image/].any? { |m| m == type }
				end

				def validate(errors, options = {})
					options[:as] ||= :images
					super(errors, options)

					unless image_type?
						errors.push([options[:as], "Invalid image mime type."])
					end
				end
			end

			module DSL
				def images(&block)
					@_images ||= Attachments.new
					@_images.dsl(&block) if block_given?
					block_given? ? self : @_images
				end
			end

			# Override default attachment class
			def attachment_class
				Image
			end
		end
	end
end

