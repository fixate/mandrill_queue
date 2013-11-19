require 'spec_helper'
require 'factories/users'

describe MandrillQueue::Message::Recipient::Helpers do
	let(:users) { FactoryGirl.build_list(:user, 2) }

	it 'converts objects to hashes' do
		described_class.objects_to_hashes(users).should == [
			users.first.attributes,
			users.last.attributes
		]
	end

	it 'converts object to hashes with field restrictions' do
		described_class.objects_to_hashes(users, [:firstname, :lastname]).should == [
			{
				firstname: users.first.firstname,
				lastname: users.first.lastname
			},
			{
				firstname: users.last.firstname,
				lastname: users.last.lastname
			}
		]
	end

	it 'should try given methods' do
		described_class.objects_to_hashes(users, nil, {try_methods: [:to_hash]}).should == [
			{
				dummy: 'hash'
			},
			{
				dummy: 'hash'
			}
		]
	end
end
