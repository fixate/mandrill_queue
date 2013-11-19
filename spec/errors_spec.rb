require 'spec_helper'

describe MandrillQueue::MandrillValidationError do
	it 'generates a concatenated message' do
		errors = [
			[:name, 'message1'],
			[:name, 'another message'],
			[:foo, 'foo message'],
		]

		txt = <<-TXT
		Validation Errors:

		- [name]: message1
		- [name]: another message
		- [foo]: foo message
		TXT

		# Check with removed whitespace, as the content is whats important here.
		described_class.new(errors).message.gsub(/\s+/, '').should == txt.gsub(/\s+/, '')
	end
end
