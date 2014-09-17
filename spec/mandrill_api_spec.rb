require 'spec_helper'

class ApiHost
  include MandrillQueue::MandrillApi
end

describe MandrillQueue::MandrillApi do
  let(:api_host) { ApiHost.new }

  describe '#mandrill' do
    subject { api_host }

    context 'not configured' do
      before do
        MandrillQueue.configure do |config|
          config.api_key = nil
        end
      end

      it 'throws error if not configured' do
        expect {
          subject.mandrill
        }.to raise_error(MandrillQueue::ConfigurationError)
      end
    end

    context 'configured' do
      before do
        MandrillQueue.configure do |config|
          config.api_key = '123456'
        end
      end

      it 'returns a new Mandrill API' do
        expect(subject.mandrill).to be_kind_of(Mandrill::API)
      end

      it 'returns a Mandrill api with the key configured' do
        expect(subject.mandrill.apikey).to eq('123456')
      end
    end
  end
end
