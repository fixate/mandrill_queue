module MandrillQueue
  module Adapters
    class SidekiqAdapter
      def enqueue_to(queue, klass, options, *args)
        client = ::Sidekiq::Client

        if options.key?(:send_at)
          client.enqueue_to_in(queue, options[:send_at], klass, *args)
        elsif options.key?(:send_in)
          client.enqueue_to_in(queue, options[:send_in], klass, *args)
        else
          client.enqueue_to(queue, klass, *args)
        end
      end
    end
  end
end
