$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'mojura'

use Rack::ContentLength
use Rack::Lint
use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger
use Rack::ETag

# Uncomment the prefered way for storing cookies.
# use Rack::Session::Memcache
use Rack::Session::Cookie, :secret => 'my_secret_cookie_string'

use Mojura::StaticFiles

use Mojura::Formatter
use Mojura::Gatekeeper

# Uncomment if your webserver doesn't support X-Sendfile (also see http://wiki.nginx.org/XSendfile)
# use Mojura::SendFiles

use Mojura::MethodOverride
use Mojura::CookieTokens

run Mojura::App.new