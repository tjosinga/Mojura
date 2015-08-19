require 'api/lib/api'
require 'webapp/mojura/lib/webapp'

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
					                             env['REQUEST_METHOD'].downcase.to_sym)
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

end
