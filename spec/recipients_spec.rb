require 'spec_helper'
require 'factories/users'

describe MandrillQueue::Message::Recipients do

	it 'adds recipients with a block' do
		subject.dsl do
			email 'test@foo.bar'
			name 'testguy'
		end
		recipients = subject.recipients
		recipients.count.should  == 1
		recipients.first.email.should == 'test@foo.bar'
		recipients.first.name.should == 'testguy'
	end

	it 'returns a array of recipients' do
		subject.add 'foo@bar.to'
		subject.add 'bar@baz.to'
		subject.to_a.should == [
			{
				email: 'foo@bar.to'
			},
			{
				email: 'bar@baz.to'
			}
		]
	end

	it 'adds a object' do
		user = FactoryGirl.build(:user)
		subject.add user, :email, :firstname
		subject.first.to_hash.should == {
			email: user.email,
			name: user.firstname
		}
	end

	context 'adding array object' do
		let(:users) { FactoryGirl.build_list(:user, 2) }

		it 'adds merge variables from an object array' do
			subject.add users, :email, :fullname

			subject.to_a.should == [
				{
					email: users.first.email,
					name: users.first.fullname
				},
				{
					email: users.last.email,
					name: users.last.fullname
				},
			]
		end

		it 'allows custom mapping' do
			subject.dsl(users) do |u|
				email u.email
				name "!#{u.fullname}!"
			end

			subject.to_a.should == [
				{
					email: users.first.email,
					name: "!#{users.first.fullname}!"
				},
				{
					email: users.last.email,
					name: "!#{users.last.fullname}!"
				},
			]
		end

		it 'uses specified field for recipient' do
			user = FactoryGirl.build(:user, { recipient: 'test@foo.bar' })
			subject.add([user], :recipient)

			subject.first.email.should == 'test@foo.bar'
		end
	end

	context 'validation' do
		it 'validates each recipient' do
			subject.add 'foo@bar.com'
			subject.add 'bar@baz.com'

			subject.recipients.each do |a|
				a.should receive(:validate)
			end
			subject.validate([])
		end
	end


end
