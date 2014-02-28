module MandrillQueue
  module Adapters
    class ResqueAdapter
      def enqueue_to(queue, klass, *args)
        ::Resque.enqueue_to(queue, klass, *args)
      end
    end
  end
end
