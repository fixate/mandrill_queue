require 'spec_helper'

describe MandrillQueue::Variables do
	subject { described_class::Internal.new }

	it 'converts to "mandrill" format' do
		subject.set!({test:'message', should: 'work'})
		subject.to_key_value_array.should == [{name: "test", content: "message"}, {name: 'should', content: "work"}]
	end

	it 'uses customized keys for key value array' do
		subject.set!({test:'message', should: 'work'})
		subject.to_key_value_array(name_key: :pity, content_key: :foos)
			.should == [
				{pity: "test", foos: "message"},
				{pity: 'should', foos: "work"}
			]
	end

	it 'responds to undefined content' do
		subject.should_not respond_to(:totes_exists)
	end

	it 'responds to defined content' do
		subject.totes_exists = true
		subject.should respond_to(:totes_exists)
	end

	it 'is set with hash' do
		subject.set!({hello: 'le monde'})
		expect { subject.hello }.to_not raise_error
		subject.hello.should == 'le monde'
	end

	it 'is not the same object as set hash' do
		hash = {foo: 'bar'}
		subject.set!(hash)
		subject.to_hash(include_nils: true).object_id.should_not == hash.object_id
	end

	it 'sets using hashes with string keys' do
		hash = {'foo' => 'bar'}
		subject.set!(hash)
		expect { subject.foo }.to_not raise_error
		subject.foo.should == 'bar'
	end

	it 'responds to indexer syntax' do
		hash = {'foo' => 'bar'}
		subject.set!(hash)

		expect{ subject[:foo] }.to_not raise_error
		subject[:foo].should == 'bar'
	end

	it 'is settable with indexer syntax' do
		subject['foo'] = 'bar'
		subject.foo.should == 'bar'
	end

	it 'is set with key value array' do
		subject.set!([{name: 'lemonde', content: 'the world'}])
		expect { subject.lemonde }.to_not raise_error
		subject.lemonde.should == 'the world'
	end

	it 'is set with key value array with custom key value keys' do
		subject.set!([{pity: 'lemonde', the_foo: 'the world'}], name_key: :pity, content_key: :the_foo)
		expect { subject.lemonde }.to_not raise_error
		subject.lemonde.should == 'the world'
	end

	it 'responds to existing methods' do
		subject.should respond_to(:to_hash, :dsl)
	end

	it 'raises an error when a variable is being retrieved and is not set' do
		expect { subject.this_totes_doesnt_exist }.to raise_error(MandrillQueue::VariableNotSetError)
	end

	it 'does not raise an error when variable has been set' do
		expect { subject.this_totes_does_exist 'fo rizzle' }.not_to raise_error
		expect { subject.this_totes_does_exist }.not_to raise_error
	end

	it 'is set by =' do
		expect{ subject.totes_is_a_cool_word = 'so is word yo' }.not_to raise_error
		subject.totes_is_a_cool_word.should == 'so is word yo'
	end

	it 'is be set by the dsl' do
		subject.dsl do
			totes_exists 'now'
			magic '!'
		end

		subject.totes_exists.should == 'now'
		subject.magic.should == '!'
	end

	it 'returns kv array without nils' do
		subject.dsl do
			something 'exists'
			but_this_is nil
		end

		subject.to_key_value_array(include_nils: false).should == [
			{name: 'something', content: 'exists'}
		]
	end

	it 'returns kv array with nils' do
		subject.dsl do
			something 'exists'
			but_this_is nil
		end

		subject.to_key_value_array(include_nils: true).should == [
			{name: 'something', content: 'exists'},
			{name: 'but_this_is', content: nil}
		]
	end

	it 'merges hashes' do
		subject.set!({a:1})
		subject.merge!({b:2})
		subject.to_hash.should == {
			a:1, b:2
		}
	end

	it 'returns hash without nils by default' do
		subject.dsl do
			nilly nil
			furtado ''
		end

		subject.to_hash.should == {
			furtado: ''
		}
	end

	it 'returns hash with nils by default' do
		subject.dsl do
			nilly nil
			furtado ''
		end

		subject.to_hash(include_nils: true).should == {
			nilly: nil,
			furtado: ''
		}
	end
end
