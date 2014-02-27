require 'spec_helper'
require 'mandrill_queue/worker'

describe MandrillQueue::Worker do
	before do
		MandrillQueue.configure do |config|
			config.api_key = 'whatever,doesnt-matter'
      config.adapter = double(:adapter, enqueue_to: true)
      config.logger = double(:logger, debug: true, warn: true, error: true, fatal: true)
		end
	end

	it 'sends with template' do
		subject.mandrill.stub(:messages).and_return(double(:messages))
		subject.mandrill.messages.should receive(:send_template)
			.with('testing', [], {}, subject.ip_pool, nil)
			.and_return([{status: 'sent'}])

		subject.perform({'template' => 'testing', 'message' => {}})
	end

	it 'sends template with content' do
		content = [
			{name: 'main', content: 'Main content'},
			{name: 'header', content: 'Header!'}
		]

		subject.mandrill.stub(:messages).and_return(double(:messages))
		subject.mandrill.messages.should receive(:send_template)
			.with('testing', content, {}, subject.ip_pool, nil)
			.and_return([{status: 'sent'}])

		subject.perform({
			'template' => 'testing',
			'message' => {},
			'content' => {
				'main' => 'Main content',
				'header' => 'Header!'
			}
		})
	end
end
