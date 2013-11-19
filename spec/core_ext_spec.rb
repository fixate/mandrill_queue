require 'spec_helper'

describe 'Ruby core extensions' do
	context String do
		it 'sluggifies any string' do
			'hello  foo_bar  '.sluggify.should == 'hello-foo-bar'
		end

		it 'converts string to underscore' do
			'SuperPowers'.underscore.should == 'super_powers'
		end
	end

	it 'returns blank? == true for blank strings and nils, otherwise false' do
		''.should be_blank
		' '.should be_blank
		nil.should be_blank

		'a'.should_not be_blank

		[].should be_blank
		[1].should_not be_blank
	end

	context Hash do
		it 'symbolizes keys!' do
			hash = {}
			hash.symbolize_keys!
			hash.should == {}

			hash = {'hello' => '', 'Foo' => 'Bar'}
			hash.symbolize_keys!
			hash.should == {hello: '', Foo: 'Bar'}

			hash = {1234 => 'foo'}
			hash.symbolize_keys!
			hash.should == {1234 => 'foo'}
		end


		it 'symbolizes keys' do
			hash = {}
			hash2 = hash.symbolize_keys
			hash2.should == {}

			hash = {'hello' => '', 'Foo' => 'Bar'}
			hash2 = hash.symbolize_keys
			hash.should == {'hello' => '', 'Foo' => 'Bar'}
			hash2.should == {hello: '', Foo: 'Bar'}

			hash = {1234 => 'foo'}
			hash.symbolize_keys.should == {1234 => 'foo'}
		end
	end
end
