require 'spec_helper'
require 'support/resque'
require 'support/mailer'

describe MandrillQueue::Mailer do
	subject { TestMailer.new }

  before(:each) do
    MandrillQueue.reset_config
    MandrillQueue.configure { |c| c.adapter = adapter }
  end
  after(:all) { MandrillQueue.reset_config }

  let(:adapter) { double(:adapter, enqueue_to: true) }

	def configure(&block)
		subject.reset!
		MandrillQueue.configure(&block)
	end

	it 'has chainable methods' do
		expect(subject.set!({})).to eq(subject)
		expect(subject.use_defaults!).to eq(subject)
		subject.message.stub(:validate)
		expect(subject.validate!).to eq(subject)
	end

	it 'sets message and content' do
		hash = {message: { to: [{email: 'blah@foo.bar', type: 'to' }]}, content: [{name: 'foo', content: 'bar'}]}
		subject.set!(hash)
		expect(subject.to_hash).to eq(hash)
	end

	it 'sets! initialized values' do
		hash = {message: { to: [] }, template: '123'}
		mailer = described_class.new(hash)
		expect(mailer.to_hash).to eq(hash)
	end

	context 'message' do
		it 'returns a message object without a block' do
			message = subject.message
			expect(message).to be_kind_of MandrillQueue::Message::Internal
		end

		it 'returns mailer with a block' do
			expect(subject.message() {}).to be_kind_of MandrillQueue::Mailer
		end

		it 'resets the message to defaults' do
			configure { |c| c.message_defaults[:subject] = 'My Subject' }
			subject.message.set!({subject: 'My Other Subject'})
			subject.reset!
			expect(subject.message.subject).to eq('My Subject')
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

			expect(subject.message.to_hash).to eq({
				to: [{email: 'foo@bar.to', type: 'to'}],
				from_email: 'foo@bar.from',
				subject: 'FooBar!'
			})

			subject.class.defaults = olddefaults
			subject.use_defaults!
		end
	end

	context 'validation' do
		it 'calls messages validate method' do
			expect(subject.message).to receive(:validate)
			subject.validate!
		end
	end

	context 'dynamic template name' do
		it 'uses the template prefix' do
			subject.class.template_prefix 'testing123-'
			expect(subject.class.foo_mail.template).to eq('testing123-foo-mail')
			subject.class.template_prefix nil
		end

		it 'correctly handles a blank template prefix' do
			subject.class.template_prefix ''
			expect(subject.class.foo_mail.template).to eq('foo-mail')
			subject.class.template_prefix nil
		end

		it 'gets all template names for mailer class' do
      subject.class.all_templates.each do |template|
        expect([
          "test-foo-mail", "test-merge-vars", "test-html-message",
          "test-recipients-from-array", "test-recipients-from-array-with-custom-mapping",
          "test-recipients", "test-delayed-email", "test-short-mailer",
          "test-default-mailer", "test-attachment-mailer"
        ]).to include(template)
      end
		end

		it 'uses called method for template name' do
			expect(subject.class.foo_mail.template).to eq('test-foo-mail')
		end

		it 'does not override the default template name' do
			olddefaults = subject.class.defaults
			subject.class.defaults { template('FooBar') }
			expect(subject.class.foo_mail.template).to eq('FooBar')
			subject.class.defaults = olddefaults
			subject.reset!
		end

		it 'does not assign a template if html/text given' do
			mailer = subject.class.html_message
			expect(mailer.template).to be_nil
		end
	end

	context 'meta data' do
		it 'returns a meta data hash without nils' do
			subject.template 'testing123'
			subject.message.nillify!

			expect(subject.to_hash).to eq({
				template: 'testing123',
				message: {}
			})
		end
	end

	context 'class level defaults' do
    freeze_time!

		it 'uses class level defaults' do
      olddefaults = subject.class.defaults

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
      expect(subject.to_hash).to eq({
        template: 'foo-bar',
        send_at: Time.now,
        message: {
          to: [{email: "test@foobar.com", type: 'to'}],
          from_email: "no-reply@foobar.com",
          subject: 'Foo Subject'
        }
      })

			subject.class.defaults = olddefaults
		end

		it 'overrides defaults from method settings' do
			expect(TestMailer.foo_mail.to_hash).to eq({
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
			})
		end

		it 'does not use settings from previous calls' do
			TestMailer.short_mailer
			# Nothing from short_mailer should be used in other call

			expect(TestMailer.default_mailer.to_hash).to eq({
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
			})
		end
	end

	context 'delivery' do
    freeze_time!

		def check_enqueue_to(*args)
			expect(adapter).to receive(:enqueue_to).with(*args)
		end

		def configure(&block)
			MandrillQueue.configure(&block)
		end

    before(:each) do
      MandrillQueue.reset_config
      MandrillQueue.configure { |c| c.adapter = adapter }
    end
    after(:all) { MandrillQueue.reset_config }

		it 'enqueues using configured class' do
			resque = double(:my_resque, enqueue_to: true)
			configure { |config| config.adapter = resque }

      expect(resque).to receive(:enqueue_to).with(subject.queue, subject.worker_class, subject.to_hash)
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
			expect(subject).to receive(:validate!)
			subject.deliver
		end

		it 'delivers hash with message data' do
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
          {type: 'to', email: 'tester@foobar.com'},
          {type: 'to', email: 'foo@bar.to'}
				],
				from_email: 'bar@baz.from',
			}

			hash = {
				template: 'foo-template',
        send_at: Time.new + 10,
				message: message,
				content: [
					{name: 'main', content: 'Main content'},
					{name: 'header', content: 'Header!'}
				]
			}

      check_enqueue_to(subject.queue, subject.worker_class, hash)
			subject.deliver
		end
	end


end

