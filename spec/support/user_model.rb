class User
	attr_accessor :email, :recipient, :firstname, :lastname

	def attributes
		{
			email: email,
			recipient: recipient,
			firstname: firstname,
			lastname: lastname
		}
	end

	def to_hash
		{
			dummy: 'hash'
		}
	end

	def fullname
		"#{firstname} #{lastname}"
	end
end
