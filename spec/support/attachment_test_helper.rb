class AttachmentTestHelper

	def self.base_path
		File.expand_path('../attachments', __FILE__)
	end

	def self.path_to(file)
		"#{base_path}/#{file}"
	end

	def self.real_file
		path_to("textfile.txt")
	end

	def self.real_image
		path_to("test.jpg")
	end
end
