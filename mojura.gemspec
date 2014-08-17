# For the meanwhile, only push to private gemserver
# gem push --host http://mojura:mojuragems@gems.mojura.nl

Gem::Specification.new do |s|
	s.name            = 'mojura'
	s.version         = '0.3.8'
	s.date            = '2014-08-17'
	s.summary         = 'Mojura'
	s.description     = 'A CMS based on a REST API, MongoDb backend and a Bootstrap frontend.'
	s.authors         = ['Taco Jan Osinga']
	s.email           = 'info@osingasoftware.nl'
	s.files           = `git ls-files lib`.split("\n") + ["LICENSE.txt", "gemfile"]
	s.executables     = ['mojura']
	s.require_paths   = ['lib']
	s.homepage        = 'http://www.mojura.nl'
	s.license         = 'MIT'

	# package dependencies
	s.add_dependency('bson', '~> 0')
	s.add_dependency('bson_ext', '~> 0')
	s.add_dependency('chunky_png', '~> 0')
	s.add_dependency('crypt', '~> 0')
	s.add_dependency('exifr', '~> 0')
	s.add_dependency('geocoder', '~> 0')
	s.add_dependency('json', '~> 0')
	s.add_dependency('kramdown', '~> 0')
	s.add_dependency('log4r', '~> 0')
	s.add_dependency('mail', '~> 0')
	s.add_dependency('memcache-client', '~> 0')
	s.add_dependency('mini_magick', '~> 0')
	s.add_dependency('mongo', '~> 0')
	s.add_dependency('mustache', '~> 0')
	s.add_dependency('openssl', '~> 0')
	s.add_dependency('prawn', '~> 0')
	s.add_dependency('rack', '~> 0')
	s.add_dependency('sanitize', '~> 0')
	s.add_dependency('xml-simple', '~> 0')
	s.add_dependency('zipruby', '~> 0')

	s.add_dependency('kvparser', '~> 0.0')
	s.add_dependency('ubbparser', '~> 0.2')
end
