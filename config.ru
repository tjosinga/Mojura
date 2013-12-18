$:.unshift(File.expand_path(File.dirname(__FILE__)))

require 'lib/mojura'

use Rack::Lint
use Rack::ContentLength
use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger
use Rack::ETag

# Uncomment if your webserver doesn't support X-Sendfile (also see http://wiki.nginx.org/XSendfile)
use Mojura::StaticFiles
use Mojura::SendFiles

# Uncomment the prefered way for storing cookies.
# use Rack::Session::Memcache
use Rack::Session::Cookie, :secret => 'my_secret_cookie_string'

use Mojura::Formatter
use Mojura::Gatekeeper

use Mojura::MethodOverride
use Mojura::CookieTokens

run Mojura::App.new