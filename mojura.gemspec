# For the meanwhile, only push to private gemserver
# gem push --host http://mojura:mojuragems@gems.mojura.nl

Gem::Specification.new do |s|
	s.name            = 'mojura'
	s.version         = '0.3.0'
	s.date            = '2014-05-23'
	s.summary         = 'Mojura'
	s.description     = 'A CMS based on a REST API, MongoDb backend and a Bootstrap frontend.'
	s.authors         = ['Taco Jan Osinga']
	s.email           = 'info@osingasoftware.nl'
	s.files           = `git ls-files lib`.split("\n") + ["LICENSE.txt", "gemfile"]
	s.executables     = ['mojura']
	s.require_paths   = ['lib']
	s.homepage        = 'http://www.mojura.nl'
	s.license         = 'MIT'
end
