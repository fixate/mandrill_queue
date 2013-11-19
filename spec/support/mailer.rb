class TestMailer < MandrillQueue::Mailer
	defaults do
		message do
			to 'tester@foobar.com'
			from_email 'no-reply@foobar.com'
		end

		content do
			value 'Content'
		end
	end

	def foo_mail
		message do
			to 'foo@bar.to'
			from_email 'bar@baz.from'
		end

		content do
			main 'Main content'
			header 'Header!'
		end
	end

	def merge_vars
		message do
			merge_vars 'test@foo.bar' do
				city_name 'Cape Town'
			end
			merge_vars 'test@bar.baz' do
				city_name 'Johannesburg'
			end
		end
	end

	def html_message
		message do
			to 'foo@bar.com'
			html '<p>test</p>'
		end
	end

	def recipients_from_array(array)
		message do
			to array, :email, :fullname
			merge_vars array, [:firstname, :lastname]
		end
	end

	def recipients_from_array_with_custom_mapping(array)
		message do
			merge_vars array, :email do |o|
				klass o.class.name
				superklass o.class.superclass.name
			end
		end
	end

	def recipients
		message do
			to 'foo@bar.to'
			to 'foo@bar.to2', 'Foo two'
			to do
				email 'foo@bar.to3'
				name 'Foo three'
			end
			cc 'foo@bar.cc'
			bcc do
				email 'foo@bar.bcc'
				name 'BCC'
			end
		end
	end

	def delayed_email
		message do
			to 'foo@bar.to'
			from_email 'bar@baz.from'
		end

		send_in Time.now + 2*24

	end

	def short_mailer
		message do
			track_clicks true
		end
	end

	def default_mailer
	end

	def attachment_mailer(name = 'Foo', header = 'HEADER!')
		message do
			to 'sdbondi@gmail.com'
			subject 'Welcome to my saht!'
			recipient_metadata 'sdbondi@gmail.com' do
				user_id 1234
			end

			attachments do
				add File.expand_path("../attachments/textfile.txt", __FILE__)
				add do
					name 'steve-brule.jpg'
					file File.expand_path("../attachments/test.jpg", __FILE__)
				end
				add do
					name 'test.txt'

					content 'Secret message'
				end
			end

			images do
				add File.expand_path("../attachments/test.jpg", __FILE__)
			end
		end

		content do
			main "Your city is #{name}"
			header header
		end
	end

end
