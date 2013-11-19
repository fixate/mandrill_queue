require 'mandrill_queue/message/recipient/data'
require 'mandrill_queue/message/recipient/variable'

class RecipientData < MandrillQueue::Message::Recipient::Data
	class Var < MandrillQueue::Message::Recipient::Variable
		variables :vars
	end
	var_class Var
end

