require 'spec_helper'
require 'support/attachment_test_helper'
require 'support/mailer'
require 'support/resque'

describe MandrillQueue::Message::Internal do
	subject { TestMailer.new.foo_mail.message }

	it 'initializes with defaults' do
		message = described_class.new(to: 'foo@bar.to', from_email: 'foo@bar.from')
		message.to.first.email.should == 'foo@bar.to'
		message.from_email.should == 'foo@bar.from'
	end

	it 'ignores invalid defaults' do
		message = nil
		expect do
			subject.set!(to: 'foo@bar.to', from_email: 'foo@bar.from', bunch: 'oh crap')
		end.not_to raise_error
		subject.to.first.email.should == 'foo@bar.to'
		subject.from_email.should == 'foo@bar.from'
		expect{subject.bunch }.to raise_error(NoMethodError)
	end

	it 'works for string and symbol keys' do
		subject.set!('to' => 'foo@bar.to')

		subject.recipients.last.should_not be_nil
		subject.recipients.last.email.should == 'foo@bar.to'
	end

	it 'uses set to set defaults' do
		described_class.any_instance.should_receive(:set!).with(to: 'foo@bar.to', from_email: 'foo@bar.from')
		described_class.new(to: 'foo@bar.to', from_email: 'foo@bar.from')
	end

	context 'recipients' do
		it 'returns correct hash of recipients' do
			hash = {
				to: [
					{email: 'tester@foobar.com', type: 'to'},
					{email: 'foo@bar.to', type: 'to'},
					{email: 'foo@bar.to2', name: 'Foo two', type: 'to'},
					{email: 'foo@bar.to3', name: 'Foo three', type: 'to'},
					{email: 'foo@bar.cc', type: 'cc'},
					{email: 'foo@bar.bcc', name: 'BCC', type: 'bcc'},
				],
				from_email: 'no-reply@foobar.com'
			}

			TestMailer.recipients.message.to_hash.should == hash
		end
	end

	context 'Attachments and images' do
		it 'loads file attachments' do
			subject.dsl do
				attachments do
					add AttachmentTestHelper.real_file
				end

				images do
					add AttachmentTestHelper.real_image
				end
			end

			subject.attachments
				.should(receive(:load_all)).with no_args
			subject.images
				.should(receive(:load_all)).with no_args

			subject.load_attachments!
		end

		it 'gets a hash of attachments and images' do
			subject.dsl do
				set!({})
				attachments do
					add AttachmentTestHelper.real_file
				end
			end

			subject.to_hash.should == {
				attachments: [
					{file: AttachmentTestHelper.real_file, type: 'text/plain', name: 'textfile.txt'}
				]
			}
		end
	end

	context 'merge vars' do
		it 'returns an array of global merge vars' do
			subject.dsl do
				global_merge_vars do
					this 'is a var'
					value '123'
				end
			end

			subject.to_hash[:global_merge_vars].should == [
				{name: 'this', content: 'is a var'},
				{name: 'value', content: '123'}
			]
		end

		it 'correctly returns merge vars' do
			subject.dsl do
				merge_vars 'test@foo.bar' do
					city_name 'Cape Town'
				end
				merge_vars 'test@bar.baz' do
					city_name 'Johannesburg'
				end
			end

			subject.to_hash[:merge_vars].should == [
				{
					rcpt: 'test@foo.bar', vars: [
						{name: 'city_name', content: 'Cape Town'},
					]
				},
				{
					rcpt: 'test@bar.baz', vars: [
						{name: 'city_name', content: 'Johannesburg'}
					]
				}
			]
		end
	end

	context 'DSL' do
		it 'is set through DSL functions' do
			subject.nillify!.dsl do
				to 'foo@bar.to'
				from_email 'foo@from.it'
				subject nil
			end

			subject.to_hash.should == {
				to: [
					{type: 'to', email: 'foo@bar.to'}
				],
				from_email: 'foo@from.it'
			}
		end

		it 'sets nil when in dsl' do
				subject.from_email.should_not be_nil

				subject.dsl do
					from_email nil
				end

				subject.from_email.should be_nil
		end
	end

	context 'hash and json' do
		before(:each) do
			subject.nillify!
			subject.dsl do
				to 'foo@bar.to'
				from_email 'foo@from.it'
			end
		end

		it 'returns hash with nils' do
			subject.to_hash(include_nils: true).should == {
				:attachments => nil,
				:auto_html => nil,
				:auto_text => nil,
				:bcc_address => nil,
				:from_email => "foo@from.it",
				:from_name => nil,
				:global_merge_vars => nil,
				:google_analytics_campaign => nil,
				:google_analytics_domain => nil,
				:headers => nil,
				:html => nil,
				:images => nil,
				:important => nil,
				:inline_css => nil,
				:merge => nil,
				:merge_vars => nil,
				:metadata => nil,
				:preserve_recipients => nil,
				:recipient_metadata => nil,
				:return_path_domain => nil,
				:signing_domain => nil,
				:subaccount => nil,
				:subject => nil,
				:tags => nil,
				:text => nil,
				:to => [{:type=>"to", :name => nil, :email=>"foo@bar.to"}],
				:track_opens => nil,
				:tracking_domain => nil,
				:track_clicks => nil,
				:url_strip_qs => nil,
				:view_content_link => nil
			}
		end

		it 'returns hash without nils' do
			subject.to_hash(include_nils: false).should == {
				to: [{email: 'foo@bar.to', type: 'to'}],
				from_email: 'foo@from.it',
			}
		end
	end

	context 'Message validation' do
		it 'returns validation error when no recipients set' do
			subject.set!({from_email: 'foo@bar.from'})

			errors = []
			subject.validate(errors)
			errors.should == [
				[:message, "Please specify at least one recipient."]
			]
		end

		it 'passes on validations' do
			subject.dsl do
				attachments { add AttachmentTestHelper.real_file }
				images { add AttachmentTestHelper.real_file }
				merge_vars 'test' do
					example 'value'
				end
				recipient_metadata 'test' do
					example 'value'
				end
			end

			subject.attachments.should receive(:validate)
			subject.images.should receive(:validate)
			subject.merge_vars.should receive(:validate)
			subject.recipient_metadata.should receive(:validate)

			errors = []
			subject.validate(errors)
		end
	end
end
