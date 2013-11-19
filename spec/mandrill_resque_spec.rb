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
end
