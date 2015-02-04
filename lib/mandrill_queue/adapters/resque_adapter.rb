module MandrillQueue
  module Adapters
    class ResqueAdapter
      def enqueue_to(queue, klass, options, *args)
        if options.key?(:send_at)
          check_for_scheduler!
          Resque.enqueue_at_with_queue(queue, options[:send_at], klass, *args)
        elsif options.key?(:send_in)
          check_for_scheduler!
          Resque.enqueue_in_with_queue(queue, options[:send_in], klass, *args)
        else
          ::Resque.enqueue_to(queue, klass, *args)
        end
      end

      def check_for_scheduler!
        raise RuntimeError, "Please install resque-scheduler to allow scheduled jobs!" \
          unless ::Resque.respond_to?(:enqueue_in)
      end
    end
  end
end
