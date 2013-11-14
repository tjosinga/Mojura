require 'rack'

module Mojura

	class MethodOverride

		def initialize(app)
			@app = app
		end

		def call(env)
#       if (env["REQUEST_METHOD"] == "POST")
			req = Rack::Request.new(env)
			env['REQUEST_METHOD'] = req.params['_method'] if (!req.params['_method'].nil?) # if (req.params["_method"] == "PUT") || (req.params["_method"] == "DELETE")
			                                                                               #       end
			@app.call(env)
		end

	end
end