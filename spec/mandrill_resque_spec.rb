require 'spec_helper'

describe MandrillQueue do
	it 'resets the config' do
		described_class.configure { |c| c.message_defaults = {to: 'foo@bar.to'} }
		described_class.configuration.message_defaults.should == {to: 'foo@bar.to'}
		described_class.reset_config do |config|
			config.message_defaults = {}
		end
		described_class.configuration.message_defaults.should == {}
	end

  it 'sets the adapter correctly' do
    described_class.reset_config
    described_class.adapter = :sidekiq
    expect(described_class.adapter).to be_kind_of(MandrillQueue::Adapters::SidekiqAdapter)

    described_class.adapter = nil
    expect(described_class.adapter).to be_kind_of(MandrillQueue::Adapters::ResqueAdapter)

    adapter = double(:adapter)
    described_class.adapter = adapter
    expect(described_class.adapter).to be(adapter)

    my_adapter = Struct.new(:enqueue_to)
    described_class.adapter = lambda { my_adapter }
    expect(described_class.adapter).to be(my_adapter)
  end

  it 'loads the configured adapter' do
    described_class.reset_config { |c| c.adapter = :sidekiq }
    expect(described_class.adapter).to be_kind_of(MandrillQueue::Adapters::SidekiqAdapter)
  end
end
