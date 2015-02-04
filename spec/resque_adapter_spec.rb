require 'spec_helper'
require 'mandrill_queue/adapters/resque_adapter'

describe MandrillQueue::Adapters::ResqueAdapter do
  it 'calls resque enqueue_to method' do
    expect(::Resque).to receive(:enqueue_to).with(:test, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, {}, 1,2,3,4)
  end

  context 'with scheduler' do
    before { allow(Resque).to receive(:enqueue_in).with(any_args) }

    it 'calls delayed enqueue_at_with_queue method with send_at option' do
      interval = 2.days.from_now

      expect(::Resque).to receive(:enqueue_at_with_queue)
        .with(:test, interval, :klass, 1,2,3,4)
      subject.enqueue_to(:test, :klass, {send_at: interval}, 1,2,3,4)
    end

    it 'calls delayed enqueue_in_with_queue method with send_in option' do
      expect(::Resque).to receive(:enqueue_at_with_queue).with(:test, 2.days, :klass, 1,2,3,4)
      subject.enqueue_to(:test, :klass, {send_at: 2.days}, 1,2,3,4)
    end
  end

  context 'without scheduler' do
    it 'raises an error when resque-scheduler isnt installed' do
      expect {
        subject.enqueue_to(:test, :klass, {send_at: 2.days}, 1,2,3,4)
      }.to raise_error(RuntimeError)
    end
  end

end
