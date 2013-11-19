require 'spec_helper'
require 'support/attachment_test_helper'

describe MandrillQueue::Message::Images do
	it 'uses Image as attachment class' do
		subject.attachment_class.should ==
			MandrillQueue::Message::Images::Image
	end
end

describe MandrillQueue::Message::Images::Image do
	it 'detects image mime types' do
		subject.type 'image/jpeg'
		subject.image_type?.should be_true
	end

	it 'returns false for non image mime types' do
		subject.type 'fake/mime'
		subject.image_type?.should be_false

		subject.type 'image/fake'
		subject.image_type?.should be_false
	end

	it 'validates image type' do
		subject.file AttachmentTestHelper.real_file
		subject.type 'image/fake'
		errors = []
		subject.validate(errors)
		errors.should == [
			[:images, 'Invalid image mime type.']
		]
	end
end
