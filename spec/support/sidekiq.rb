module Sidekiq
  class Client
    def enqueue_to(*args)

    end
  end
	def self.stub_me!
		stub(:perform_async)
	end
end

