# = Mojura
# Mojura is a API centered Content Management System, developed by Taco Jan Osinga of {Osinga Software}[www.osingasoftware.nl].
#
# This file contains the App classes which is the base class for Mojura.

require 'api/lib/api'
require 'webapp/mojura/lib/webapp'

module Mojura

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
					error[:modules] = MojuraAPI::API.modules if (MojuraAPI::Settings.get(:developing, false))
					error[:backtrace] = [e.backtrace] if (MojuraAPI::Settings.get(:developing, false))
					code = (e.is_a?(MojuraAPI::HTTPException)) ? e.code : 500
					return [code, {}, [{error: error}]]
				end
			else
				begin
					MojuraWebApp::WebApp.init_thread(env)
					result = MojuraWebApp::WebApp.render(env['PATH_INFO'].gsub(/\/*$/, '').gsub(/^\/*/, ''), request.params)
					return [200, MojuraWebApp::WebApp.headers, [result]]
				rescue Exception => e
					code = (e.is_a?(MojuraAPI::HTTPException)) ? e.code : 500
					return [code, {}, [e.message]]
				end
			end
		end

	end

end