require 'rails'

module MandrillQueue
	module Generators
		class InitializerGenerator < Rails::Generators::Base
			source_root File.expand_path('../templates', __FILE__)

			desc "Creates a default MandrillQueue initializer."
			def create_initializer_file
				copy_file 'initializer.rb', "config/initializers/mandrill_queue.rb"
			end
		end
	end
end
