RSpec.configure do |config|
	config.before :all do
		Excon.defaults[:mock] = true
		Excon.stub({}, {body: {
			status: 'sent', _id: 'dummyid12345', email: 'test@foo.bar'
		}.to_json, status: 200})
	end
end
