require 'spec_helper'
require 'mandrill_queue/adapters/sidekiq_adapter'

describe MandrillQueue::Adapters::SidekiqAdapter do
  it 'calls sidekiq client enqueue_to method' do
    expect(::Sidekiq::Client).to receive(:enqueue_to).with(:test, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, {}, 1,2,3,4)
  end

  it 'calls enqueue_to_in with send_at option' do
    time = 2.hours.from_now
    expect(::Sidekiq::Client).to receive(:enqueue_to_in).with(:test, time, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, {send_at: time}, 1,2,3,4)
  end

  it 'calls enqueue_to_in with send_in option' do
    expect(::Sidekiq::Client).to receive(:enqueue_to_in).with(:test, 2.hours, :klass, 1,2,3,4)
    subject.enqueue_to(:test, :klass, {send_in: 2.hours}, 1,2,3,4)
  end
end
