require 'spec_helper'

describe MandrillQueue::Message::RecipientMetadata do
	it 'adds merge var objects' do
		subject.add 'test@foo.bar'
		subject.recipient_metadata.count.should == 1
	end

	it 'adds merge vars with a block' do
		subject.add 'test@foo.bar' do
			var 'value'
		end

		metadata = subject.recipient_metadata
		metadata.count.should  == 1
		metadata.first.recipient.should == 'test@foo.bar'
		metadata.first.values.to_hash.should == {var: 'value'}
	end

	it 'returns a array of metadata' do
		subject.add('foo@bar.to') { foo 'bar' }
		subject.add 'bar@baz.to' do
			name 'test'
		end

		subject.to_a.should == [
			{
				rcpt: 'foo@bar.to',
				values: [
					{name: 'foo', content: 'bar'}
				]
			},
			{
				rcpt: 'bar@baz.to',
				values: [
					{name: 'name', content: 'test'}
				]
			}
		]
	end

	context 'validation' do
		it 'validates each attachment' do
			subject.add do
			end

			subject.recipient_metadata.each do |a|
				a.should receive(:validate)
			end
			subject.validate([])
		end
	end


end

describe MandrillQueue::Message::RecipientMetadata::Metadatum do
	it 'sets the recipient' do
		subject.recipient 'test@test'
		subject.recipient.should == 'test@test'
	end

	it 'returns correct hash' do
		subject.recipient 'test@test'
		subject.dsl do
			testing 'vars'
			are 'everywhere'
		end

		subject.to_hash.should == {
			rcpt: 'test@test',
			values:[
				{name: 'testing', content:'vars'},
				{name: 'are', content: 'everywhere'}
			]
		}
	end

	it 'is set' do
		subject.set!({
			rcpt: 'tester@foo.com',
			values: {
				testing: 'vars',
				from: 'a hash'
			}
		})

		subject.to_hash.should == {
			rcpt: 'tester@foo.com',
			values: [
				{name: 'testing', content: 'vars'},
				{name: 'from', content: 'a hash'}
			]
		}
	end

	it 'returns no vars if set to nil' do
		subject.set!({})
		subject.to_hash.should == { }
	end

end
