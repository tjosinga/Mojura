$:.unshift File.join(File.dirname(__FILE__), '..')

Dir::foreach('./') { |name|
	if (name != '.') && (name != '..') && (name != 'all.rb')
		require './' + name
	end
}
