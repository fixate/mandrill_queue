require 'spec_helper'
require 'support/resque'
require 'support/mailer'

describe MandrillQueue::Mailer do
	subject { TestMailer.new }
  # before(:each) { MandrillQueue.reset_config }
	# after { MandrillQueue.reset_config }

  before do
    MandrillQueue.configure do |c|
      c.adapter = double(:adapter, enqueue_to: true)
    end
  end

	def configure(&block)
		subject.reset!
		MandrillQueue.configure(&block)
	end

	it 'has chainable methods' do
		subject.set!({}).should == subject
		subject.use_defaults!.should == subject
		subject.message.stub(:validate)
		subject.validate!.should == subject
	end

	it 'sets message and content' do
		hash = {message: { to: [{email: 'blah@foo.bar', type: 'to' }]}, content: [{name: 'foo', content: 'bar'}]}
		subject.set!(hash)
		subject.to_hash.should == hash
	end

	it 'sets! initialized values' do
		hash = {message: { to: [] }, template: '123'}
		mailer = described_class.new(hash)
		mailer.to_hash.should == hash
	end

	context 'message' do
		it 'returns a message object without a block' do
			message = subject.message
			message.should be_kind_of MandrillQueue::Message::Internal
		end

		it 'returns mailer with a block' do
			subject.message() {}.should be_kind_of MandrillQueue::Mailer
		end

		it 'resets the message to defaults' do
			configure { |c| c.message_defaults[:subject] = 'My Subject' }
			subject.message.set!({subject: 'My Other Subject'})
			subject.reset!
			subject.message.subject.should == 'My Subject'
		end
	end

	context 'configuration' do
		it 'configures message defaults with overrides' do
			olddefaults, subject.class.defaults = subject.class.defaults, nil

			configure do |config|
				config.message_defaults = {
					to: 'foo@bar.to',
					from_email: 'foo@bar.from',
					subject: 'FooBar!'
				}
			end

			subject.message.to_hash.should == {
				to: [{email: 'foo@bar.to', type: 'to'}],
				from_email: 'foo@bar.from',
				subject: 'FooBar!'
			}

			subject.class.defaults = olddefaults
			subject.use_defaults!
		end
	end

	context 'validation' do
		it 'calls messages validate method' do
			subject.message.should receive(:validate)
			subject.validate!
		end
	end

	context 'dynamic template name' do
		it 'uses the template prefix' do
			subject.class.template_prefix 'testing123-'
			subject.class.foo_mail.template.should == 'testing123-foo-mail'
			subject.class.template_prefix nil
		end

		it 'correctly handles a blank template prefix' do
			subject.class.template_prefix ''
			subject.class.foo_mail.template.should == 'foo-mail'
			subject.class.template_prefix nil
		end

		it 'gets all template names for mailer class' do
      subject.class.all_templates.each do |template|
        [
          "test-foo-mail", "test-merge-vars", "test-html-message",
          "test-recipients-from-array", "test-recipients-from-array-with-custom-mapping",
          "test-recipients", "test-delayed-email", "test-short-mailer",
          "test-default-mailer", "test-attachment-mailer"
        ].should include(template)
      end
		end

		it 'uses called method for template name' do
			subject.class.foo_mail.template.should == 'test-foo-mail'
		end

		it 'does not override the default template name' do
			olddefaults = subject.class.defaults
			subject.class.defaults { template('FooBar') }
			subject.class.foo_mail.template.should == 'FooBar'
			subject.class.defaults = olddefaults
			subject.reset!
		end

		it 'does not assign a template if html/text given' do
			mailer = subject.class.html_message
			mailer.template.should be_nil
		end
	end

	context 'meta data' do
		it 'returns a meta data hash without nils' do
			subject.template 'testing123'
			subject.message.nillify!

			subject.to_hash.should == {
				template: 'testing123',
				message: {}
			}
		end
	end

	context 'class level defaults' do
		it 'uses class level defaults' do
			olddefaults = subject.class.defaults

			Timecop.freeze(Time.now) do
				subject.class.defaults do
					template 'foo-bar'
					send_at Time.now

					message do
						to 'test@foobar.com'
						from_email 'no-reply@foobar.com'
						subject 'Foo Subject'
					end
				end

				subject.use_defaults!
				subject.to_hash.should == {
					template: 'foo-bar',
					send_at: Time.now,
					message: {
						to: [{email: "test@foobar.com", type: 'to'}],
						from_email: "no-reply@foobar.com",
						subject: 'Foo Subject'
					}
				}

			end

			subject.class.defaults = olddefaults
		end

		it 'overrides defaults from method settings' do
			TestMailer.foo_mail.to_hash.should == {
				template: 'test-foo-mail',
				message: {
					to: [
						{type: 'to', email: 'tester@foobar.com'},
						{type: 'to', email: 'foo@bar.to'}
					],
					from_email: 'bar@baz.from',
				},
				content: [
					{name: 'value', content: 'Content'},
					{name: 'main', content: 'Main content'},
					{name: 'header', content: 'Header!'}
				]
			}
		end

		it 'does not use settings from previous calls' do
			TestMailer.short_mailer
			# Nothing from short_mailer should be used in other call

			TestMailer.default_mailer.to_hash.should == {
				template: 'test-default-mailer',
				message: {
					from_email: 'no-reply@foobar.com',
					to: [
						{type: 'to', email: 'tester@foobar.com'}
					]
				},
				content: [
					{name: 'value', content: 'Content'}
				]
			}
		end
	end

	context 'delivery' do
		# before(:each) { MandrillQueue.reset_config }
		# after(:all) { MandrillQueue.reset_config }

		def check_enqueue_to(*args)
			Resque.should receive(:enqueue_to).with(*args)
		end

		def configure(&block)
			MandrillQueue.configure(&block)
		end

		it 'enqueues using configured class' do
			resque = double(:my_resque)
			configure do |config|
				config.adapter = resque
			end

			resque.should receive(:enqueue_to).with(subject.queue, subject.worker_class, subject.to_hash)
			subject.deliver
		end

		it 'uses the built-in worker' do
			check_enqueue_to(subject.queue, MandrillQueue::Worker, subject.to_hash)
			subject.deliver
		end

		it 'uses configured worker class' do
			my_worker = double(:worker)
			configure do |config|
				config.default_worker_class = my_worker
			end

			check_enqueue_to(subject.queue, my_worker, subject.to_hash)
			subject.deliver
		end

		it 'uses mailers overriden worker class' do
			my_worker = double(:worker)
			subject.stub(:worker_class).and_return(my_worker)

			check_enqueue_to(subject.queue, my_worker, subject.to_hash)
			subject.deliver
		end

		it 'uses the configured queue' do
			configure do |config|
				config.default_queue = :foo_queue
			end

			check_enqueue_to(:foo_queue, subject.worker_class, subject.to_hash)
			subject.deliver
		end

		it 'uses the overriden queue in mailer' do
			subject.stub(:queue).and_return(:bar_queue)

			check_enqueue_to(:bar_queue, subject.worker_class, subject.to_hash)
			subject.deliver
		end

		it 'uses the overriden queue in worker' do
			subject.worker_class.stub(:queue).and_return(:bar_worker_queue)

			check_enqueue_to(:bar_worker_queue, subject.worker_class, subject.to_hash)
			subject.deliver
		end

		it 'validates on delivery' do
			Resque.stub_me!

			subject.should receive(:validate!)
			subject.deliver
		end

		it 'delivers hash with message data' do
			Timecop.freeze(Time.now)
			subject.dsl do
				message do
					to 'foo@bar.to'
					from_email 'bar@baz.from'
				end
				template 'foo-template'
				send_at Time.now + 10
				content do
					main 'Main content'
					header 'Header!'
				end
			end

			message = {
				to: [
					{email: 'tester@foobar.com', type: 'to'},
					{email: 'foo@bar.to', type: 'to'}
				],
				from_email: 'bar@baz.from',
			}

			hash = {
				send_at: Time.new + 10,
				template: 'foo-template',
				message: message,
				content: [
					{name: 'main', content: 'Main content'},
					{name: 'header', content: 'Header!'}
				]
			}

			Resque.should receive(:enqueue_to).with(subject.queue, subject.worker_class, hash)
			subject.deliver

			Timecop.return
		end
	end


end

