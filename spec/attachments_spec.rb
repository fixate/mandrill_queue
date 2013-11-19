require 'spec_helper'
require 'support/attachment_test_helper'

def b64(str); Base64.encode64(str); end

describe MandrillQueue::Message::Attachments do

	it 'adds attachment objects' do
		subject.add AttachmentTestHelper.real_file
		subject.instance_variable_get(:@_attachments).count.should  == 1
	end

	it 'adds attachments with a block' do
		subject.add do
			name 'test'
			content '1234'
			type 'text/plain'
		end

		attachments = subject.instance_variable_get(:@_attachments)
		attachments.count.should  == 1
		attachments.first.name.should == 'test'
		attachments.first.content.should == b64('1234')
		attachments.first.type.should == 'text/plain'
	end

	it 'returns a array of attachments' do
		subject.add AttachmentTestHelper.real_file
		subject.add do
			name 'test'
			content '1234'
			type 'text/plain'
		end

		subject.to_a.should == [
			{
				file: AttachmentTestHelper.real_file,
				name: 'textfile.txt',
				type: 'text/plain'
			},
			{
				name: 'test',
				content: b64('1234'),
				type: 'text/plain'
			}
		]
	end

	it 'uses attachment_class for attachments' do
		attachment = double(:attachment)
		subject.instance_variable_set(:@_klass, attachment)
		attachment.should receive(:new).with(AttachmentTestHelper.real_file)
		subject.dsl do
			add AttachmentTestHelper.real_file
		end

		subject.instance_variable_set(:@_klass, nil)
	end

	context 'validation' do
		it 'validates each attachment' do
			subject.dsl do
				add AttachmentTestHelper.real_file
				add AttachmentTestHelper.real_image
			end

			subject.attachments.each do |a|
				a.should receive(:validate).with([], {as: :test})
			end
			subject.validate([], as: :test)
		end

		it 'validates as a given key' do
			subject.add 'not-real!'

			errors = []
			subject.validate(errors, as: :test)
			errors.first.first.should == :test
		end
	end
end

describe MandrillQueue::Message::Attachments::Attachment do
	it 'uses the file name for name' do
		subject.file AttachmentTestHelper.real_file
		subject.name.should == File.basename(AttachmentTestHelper.real_file)
	end

	it 'uses the correct mime type for a file' do
		subject.file AttachmentTestHelper.real_file
		subject.type.should == 'text/plain'

		subject.file AttachmentTestHelper.real_image
		subject.type.should == 'image/jpeg'
	end

	it 'loads existing file' do
		subject.file AttachmentTestHelper.real_file
		contents = "This is an example attachment\n"
		subject.load_file
		subject.type.should == 'text/plain'
		subject.content.should == b64(contents)
	end

	it 'has a type parameter of string type' do
		subject.file AttachmentTestHelper.real_file
		subject.type.should be_kind_of String
	end

	it 'is settable' do
		subject.content '1234'
		subject.set!({file: AttachmentTestHelper.real_file, name: '1234', type: 'foo/mime'})

		subject.file.should == AttachmentTestHelper.real_file
		subject.name.should == '1234'
		subject.type.should == 'foo/mime'
		subject.content.should be_nil
	end

	it 'uses default mime' do
		subject.type.should == 'application/octet-stream'
	end

	context 'validation' do
		it 'validates file and content' do
			subject.name 'test'
			errors = []
			subject.validate(errors)

			errors.should == [[:attachments, "No file or content for attachment 'test'."]]
		end

		it 'validates attachment name' do
			subject.content '1234'

			subject.validate(errors = [])
			errors.should == [[:attachments, "No attachment name given."]]
		end

		it 'validates file existance' do
			subject.file 'ye-i-dont-exist'

			errors = []
			subject.validate(errors)
			errors.should == [[:attachments, "File to load (ye-i-dont-exist) does not exist."]]
		end

		it 'validates as given key' do
			errors = []
			subject.validate(errors, as: :foo)

			errors.first.first.should == :foo
		end
	end
end
