$:.unshift File.join(File.dirname(__FILE__), '..')

Dir::foreach('./') { | name |
	if (name.end_with?('.rb')) && (name != 'all.rb')
		require './' + name
	end
}
