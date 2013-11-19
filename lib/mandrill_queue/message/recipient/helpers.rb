module MandrillQueue
	module Message
		module Recipient
			module Helpers
				def self.objects_to_hashes(list, fields = nil, options = {})
					try_methods = options[:try_methods] || [:attributes, :to_hash, :to_h]
					hashes = []
					list.each do |obj|
						hashes << if obj.is_a?(Hash)
							fields.nil? ? obj.dup : obj.select { |o| fields.include?(o) }
						elsif fields.nil?
							meth = try_methods.find { |m| obj.respond_to?(m) }
							# Add object result or nil
							unless meth.nil?
								obj.send(meth)
							end
						else
							hash = {}
							fields.each do |f|
								hash[f] = obj.send(f)
							end
							hash
						end
					end
					hashes
				end
			end
		end
	end
end
