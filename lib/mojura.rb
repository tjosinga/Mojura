# = Mojura
# Mojura is a API centered Content Management System, developed by Taco Jan Osinga of {Osinga Software}[www.osingasoftware.nl].
#
# This file contains the App classes which is the base class for Mojura.

$:.unshift(File.expand_path(File.dirname(__FILE__) + '/mojura/'))

require 'rack'
require 'json'

require 'middleware/staticfiles'
require 'middleware/gatekeeper'
require 'middleware/methodoverride'
require 'middleware/cookietokens'
require 'middleware/formatter'
require 'middleware/sendfiles'
require 'middleware/gem_versions'

require 'lib/plugins_manager'
require 'lib/filename_checker'
require 'lib/app'

# Forcing UTF-8 encoding
Encoding.default_external = Encoding::UTF_8


