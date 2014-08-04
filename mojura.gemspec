# For the meanwhile, only push to private gemserver
# gem push --host http://mojura:mojuragems@gems.mojura.nl

Gem::Specification.new do |s|
	s.name            = 'mojura'
	s.version         = '0.3.7'
	s.date            = '2014-08-04'
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
	s.add_dependency('bson')
	s.add_dependency('bson_ext')
	s.add_dependency('chunky_png')
	s.add_dependency('crypt')
	s.add_dependency('exifr')
	s.add_dependency('geocoder')
	s.add_dependency('json')
	s.add_dependency('kramdown')
	s.add_dependency('log4r')
	s.add_dependency('mail')
	s.add_dependency('memcache-client')
	s.add_dependency('mini_magick')
	s.add_dependency('mongo')
	s.add_dependency('mustache')
	s.add_dependency('pbkdf2')
	s.add_dependency('prawn')
	s.add_dependency('rack')
	s.add_dependency('xml-simple')
	s.add_dependency('zipruby')
	s.add_dependency('kvparser')
	s.add_dependency('ubbparser')

end
