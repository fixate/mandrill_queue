module MandrillQueue
  module Adapters
    class SidekiqAdapter
      def enqueue_to(queue, klass, *args)
        ::Sidekiq::Client.enqueue_to(queue, klass, *args)
      end
    end
  end
end
