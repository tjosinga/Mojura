$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'memcache'
require 'rack'
require 'app'
require 'json'

require 'middleware/gatekeeper'
require 'middleware/methodoverride'
require 'middleware/cookietokens'
require 'middleware/formatter'
require 'middleware/multigetter'

use Rack::Lint
use Rack::ContentLength
use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger
use Rack::Session::Memcache
use Rack::ETag

use Mojura::Formatter
use Mojura::Gatekeeper
use Mojura::MethodOverride
use Mojura::CookieTokens

run Mojura::App.new