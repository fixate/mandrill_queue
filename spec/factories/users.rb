require 'support/user_model'

FactoryGirl.define do
	factory :user do
		email { Faker::Internet.email }
		firstname { Faker::Name.first_name }
		lastname { Faker::Name.last_name }
	end
end
