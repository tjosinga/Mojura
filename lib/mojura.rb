# = Mojura
# Mojura is a API centered Content Management System, developed by Taco Jan Osinga of {Osinga Software}[www.osingasoftware.nl].
#
# This file contains the App classes which is the base class for Mojura.

$:.unshift(File.expand_path(File.dirname(__FILE__) + '/mojura/'))

require 'rack'
require 'json'

require 'api/lib/api'
require 'webapp/mojura/lib/webapp'

require 'middleware/staticfiles'
require 'middleware/gatekeeper'
require 'middleware/methodoverride'
require 'middleware/cookietokens'
require 'middleware/formatter'
require 'middleware/sendfiles'
require 'middleware/gem_versions'

# Forcing UTF-8 encoding
Encoding.default_external = Encoding::UTF_8


module Mojura
	extend self

	class App

		def call(env)
			MojuraAPI::API.init_thread(env)
			request = Rack::Request.new(env)
			if env['is_api_call']
				begin
					result = MojuraAPI::API.call(env['PATH_INFO'].gsub(/\/*$/, '').gsub(/^\/*/, ''),
					                             request.params,
					                             env['REQUEST_METHOD'].downcase)
					return [200, MojuraAPI::API.headers, [result]]
				rescue Exception => e
					error = {message: e, type: e.class}
					error[:modules] = MojuraAPI::API.modules if (MojuraAPI::Settings.get_b(:developing))
					error[:backtrace] = [e.backtrace] if (MojuraAPI::Settings.get_b(:developing))
					code = (e.is_a?(MojuraAPI::HTTPException)) ? e.code : 500
					return [code, {}, [{error: error}]]
				end
			else
				begin
					MojuraWebApp::WebApp.init_thread(env)
					result = MojuraWebApp::WebApp.render(env['PATH_INFO'].gsub(/\/*$/, '').gsub(/^\/*/, ''), request.params)
					return [result[:status], MojuraWebApp::WebApp.headers, [result[:html]]]
				rescue MojuraWebApp::RedirectException => e
					return [e.code, {'Location' => e.url}, []]
				rescue Exception => e
					code = (e.is_a?(MojuraAPI::HTTPException)) ? e.code : 500
					return [code, {}, [e.message]]
				end
			end
		end

	end

	PATH = File.dirname(__FILE__) + '/mojura/'

	# Checks wether the given filename is available in the project or the gem and returns the correct filename.
	# Returns an empty string if the file does not exists.
	def filename(filename)
		if File.exists?(filename)
			return filename
		elsif File.exists?("#{PATH}/#{filename}")
			return "#{PATH}/#{filename}"
		else
			return ''
		end
	end

end