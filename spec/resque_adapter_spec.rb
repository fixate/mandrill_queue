require 'spec_helper'
require 'mandrill_queue/adapters/resque_adapter'

describe MandrillQueue::Adapters::ResqueAdapter do
  it 'calls resque enqueue_to method' do
    expect(::Resque).to receive(:enqueue_to).with(:test, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, 1,2,3,4)
  end
end
