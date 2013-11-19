require 'spec_helper'
require 'factories/users'
require 'support/recipient_data'

describe MandrillQueue::Message::Recipient::Data do
	subject{ RecipientData.new }
	let(:users) { FactoryGirl.build_list(:user, 2) }

	it 'adds a list of objects to data' do
		subject.add(users)
		obj = subject.recipient_data
		obj.should be_kind_of(Array)
		obj.count.should == 2
		obj.first.should be_kind_of RecipientData::Var
		obj.first.recipient.should == users.first.email
		obj.first.vars[:firstname].should == users.first.firstname
		obj.first.vars[:lastname].should == users.first.lastname
	end

	it 'uses specified field for recipient' do
		user = FactoryGirl.build(:user, { recipient: 'test@foo.bar' })
		subject.add([user], :recipient)

		subject.first.recipient.should == 'test@foo.bar'
	end

	it 'defines a method on the inherited class which returns the data' do
		subject.should respond_to(:recipient_data)
		subject.recipient_data.should be_kind_of(Array)
	end

	it 'merges recipients added from multiple calls' do
		subject.add('foo@bar.to') { firstname 'foo' }
		subject.add('foo@bar.to') { lastname 'bar' }

		subject.count.should == 1
		subject.first.variables.to_hash.should == {
			firstname: 'foo',
			lastname: 'bar'
		}
	end

	it 'creates an array of objects' do
		subject.add(users)
		subject.to_a.should == [
			{
				rcpt: users.first.email,
				vars: [
					{name: 'email', content: users.first.email},
					{name: 'firstname', content: users.first.firstname},
					{name: 'lastname', content: users.first.lastname}
				]
			},
			{
				rcpt: users.last.email,
				vars: [
					{name: 'email', content: users.last.email},
					{name: 'firstname', content: users.last.firstname},
					{name: 'lastname', content: users.last.lastname}
				]
			},
		]
	end

	it 'uses custom mapping' do
		subject.add users do |u|
			name "#{u.firstname} #{u.lastname}"
		end

		user = users.first
		subject.first.variables.name.should == "#{user.firstname} #{user.lastname}"
	end
end
