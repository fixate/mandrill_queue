require 'rails'

module MandrillQueue
	module Generators
		class WorkerGenerator < Rails::Generators::Base
			source_root File.expand_path('../templates', __FILE__)

			desc "Creates an default worker entrypoint for rake resque:work -r ./worker.rb"
			def create_worker_file
				copy_file 'worker.rb', "./worker.rb"

				puts 'Worker created! You can run it with the following command:'
				puts 'cd worker; QUEUES=mailer rake resque:work -r ./worker.rb'
			end
		end
	end
end
