Gem::Specification.new do |s|
	s.name            = 'mojura'
	s.version         = '0.1.5'
	s.date            = '2014-02-10'
	s.summary         = 'Mojura'
	s.description     = 'A CMS based on a REST API, MongoDb backend and a Bootstrap frontend'
	s.authors         = ['Taco Jan Osinga']
	s.email           = 'info@osingasoftware.nl'
	s.files           = `git ls-files lib`.split("\n") + ["LICENSE.txt", "gemfile"]
	s.executables     = ['mojura']
	s.require_paths   = ['lib']
	s.homepage        = 'http://www.mojura.nl'
	s.license         = 'MIT'
end
