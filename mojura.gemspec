# For the meanwhile, only push to private gemserver
# gem push --host http://mojura:mojuragems@gems.mojura.nl

Gem::Specification.new do |s|
	s.name            = 'mojura'
	s.version         = '0.15.2'
	s.date            = '2015-09-21'
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
	s.add_runtime_dependency('bson', '>= 0')
	s.add_runtime_dependency('bson_ext', '>= 0')
	s.add_runtime_dependency('chunky_png', '>= 0')
	s.add_runtime_dependency('crypt', '>= 0')
	s.add_runtime_dependency('exifr', '>= 0')
	s.add_runtime_dependency('geocoder', '>= 0')
	s.add_runtime_dependency('json', '>= 0')
	s.add_runtime_dependency('kramdown', '>= 0')
	s.add_runtime_dependency('log4r', '>= 0')
	s.add_runtime_dependency('mail', '>= 0')
	s.add_runtime_dependency('memcache-client', '>= 0')
	s.add_runtime_dependency('mini_magick', '>= 0')
	s.add_runtime_dependency('mongo', '>= 0')
	s.add_runtime_dependency('mustache', '>= 0')
	s.add_runtime_dependency('prawn', '>= 0')
	s.add_runtime_dependency('rack', '>= 0')
	s.add_runtime_dependency('sanitize', '>= 0')
	s.add_runtime_dependency('xml-simple', '>= 0')
	s.add_runtime_dependency('zipruby', '>= 0')

	s.add_runtime_dependency('kvparser', '>= 0')
	s.add_runtime_dependency('ubbparser', '>= 0')
end
