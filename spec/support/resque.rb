module Resque
	class Logging
	end

	def self.stub_me!
		stub(:enqueue_to)
		[:info, :error, :warn, :debug, :fatal].each do |method|
			Resque::Logging.stub(method)
		end
	end
end

