require 'mandrill_queue/variables'
require 'mandrill_queue/message/recipient/data'
require 'mandrill_queue/message/recipient/variable'

module MandrillQueue
	module Message
		class MergeVars < Recipient::Data

			class Var < Recipient::Variable
				variables :vars
			end

			var_class Var

			module DSL
				def merge_vars(*args, &block)
					@_merge_vars ||= MergeVars.new
					@_merge_vars.dsl(*args, &block) if args.count > 0 || block_given?
					block_given? ? self : @_merge_vars
				end
			end
		end
	end
end
