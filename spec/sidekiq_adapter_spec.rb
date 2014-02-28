require 'spec_helper'
require 'mandrill_queue/adapters/sidekiq_adapter'

describe MandrillQueue::Adapters::SidekiqAdapter do
  it 'calls sidekiq client enqueue_to method' do
    expect(::Sidekiq::Client).to receive(:enqueue_to).with(:test, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, 1,2,3,4)
  end
end
