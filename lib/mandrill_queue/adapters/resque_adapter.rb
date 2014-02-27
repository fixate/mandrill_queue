module MandrillQueue
  module Adapters
    class ResqueAdapter
      def enqueue_to(*args)
        ::Resque.enqueue_to(*args)
      end
    end
  end
end
