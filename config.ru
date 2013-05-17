$:.unshift(File.expand_path(File.dirname(__FILE__)))

#require 'memcache'
require 'rack'
require 'app'
require 'json'

require 'middleware/staticfiles'
require 'middleware/gatekeeper'
require 'middleware/methodoverride'
require 'middleware/cookietokens'
require 'middleware/formatter'
require 'middleware/sendfiles'

use Mojura::StaticFiles

use Rack::Lint
use Rack::ContentLength
use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger
use Rack::ETag

# Uncomment the prefered way for storing cookies.
# use Rack::Session::Memcache
use Rack::Session::Cookie, :secret => 'my_secret_cookie_string'


use Mojura::Formatter
use Mojura::Gatekeeper

# Uncomment if your webserver doesn't support X-Sendfile (also see http://wiki.nginx.org/XSendfile)
use Mojura::SendFiles

use Mojura::MethodOverride
use Mojura::CookieTokens

run Mojura::App.new