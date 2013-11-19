require 'spec_helper'
require 'factories/users'

describe MandrillQueue::Message::MergeVars do
	it 'adds merge var objects' do
		subject.add 'test@foo.bar'
		subject.merge_vars.count.should == 1
	end

	it 'adds merge vars with a block' do
		subject.add 'test@foo.bar' do
			var 'value'
		end

		merge_vars = subject.merge_vars
		merge_vars.count.should  == 1
		merge_vars.first.recipient.should == 'test@foo.bar'
		merge_vars.first.vars.to_hash.should == {var: 'value'}
	end

	it 'returns a array of merge_vars' do
		subject.add('foo@bar.to') { foo 'bar' }
		subject.add 'bar@baz.to' do
			name 'test'
		end

		subject.to_a.should == [
			{
				rcpt: 'foo@bar.to',
				vars: [
					{name: 'foo', content: 'bar'}
				]
			},
			{
				rcpt: 'bar@baz.to',
				vars: [
					{name: 'name', content: 'test'}
				]
			}
		]
	end

	context 'adding array object' do
		let(:users) { FactoryGirl.build_list(:user, 2) }

		it 'adds merge variables from an object array' do
			subject.add(users, [:firstname, :lastname])

			subject.to_a.should == [
				{
					rcpt: users.first.email,
					vars: [
						{name: 'firstname', content: users.first.firstname},
						{name: 'lastname', content: users.first.lastname},
					]
				}, {
					rcpt: users.last.email,
					vars: [
						{name: 'firstname', content: users.last.firstname},
						{name: 'lastname', content: users.last.lastname },
					]
				}
			]
		end

		it 'uses specified field for recipient' do
			user = FactoryGirl.build(:user, { recipient: 'test@foo.bar' })
			subject.add([user], :recipient)

			subject.first.recipient.should == 'test@foo.bar'
		end

		it 'is populated by hashes' do
			subject.add([{email: 'test@foo.bar', firstname: 'foo', lastname: 'bar'}])

			subject.first.recipient.should == 'test@foo.bar'
			subject.first.vars.firstname.should == 'foo'
			subject.first.vars.lastname.should == 'bar'
		end

		it 'uses custom mapping' do
			subject.dsl users do |u|
				name "#{u.firstname}+#{u.lastname}"
			end

			user = users.first
			subject.first.recipient.should == user.email
			subject.first.variables.name.should == "#{user.firstname}+#{user.lastname}"
		end
	end

	context 'validation' do
		it 'validates each attachment' do
			subject.add do
			end

			subject.merge_vars.each do |a|
				a.should receive(:validate)
			end
			subject.validate([])
		end
	end

end

describe MandrillQueue::Message::MergeVars::Var do
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
			vars: [
				{name: 'testing', content: 'vars'},
				{name: 'are', content: 'everywhere'}
			]
		}
	end

	it 'is set' do
		subject.set!({
			rcpt: 'tester@foo.com',
			vars: {
				testing: 'vars',
				from: 'a hash'
			}
		})

		subject.to_hash.should == {
			rcpt: 'tester@foo.com',
			vars: [
				{name: 'testing', content: 'vars'},
				{name: 'from', content: 'a hash'}
			]
		}
	end

	it 'returns merge_var when set! is called' do
		subject.set!({}).should == subject
	end

	it 'returns no vars if set to nil' do
		subject.set!({})
		subject.to_hash.should == { }
	end

	context 'validation' do
		it 'validates recipient' do
			subject.recipient = nil
			errors = []
			subject.validate(errors)
			errors.should == [
				[:var, 'Recipient cannot be empty.']
			]
		end
	end
end
