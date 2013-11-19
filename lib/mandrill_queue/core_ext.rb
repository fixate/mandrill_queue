require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/array'

class String
	def sluggify
		value = self
    value.gsub!(/[']+/, '')
    value.gsub!(/\W+/, ' ')
    value.strip!
    value.downcase!
		value.gsub!(/[^A-Za-z0-9]/, '-')
    value
	end
end
