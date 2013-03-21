module MojuraAPI

	class HTTPException < Exception
		attr_reader :code

		def initialize(error_string, error_code = 500)
			@code = error_code
			super(error_string)
		end
	end

	class UnsupportedMethodException < HTTPException
		def initialize(method)
			super("Unknown method: #{method}", 501)
		end
	end

	class UnknownModuleException < HTTPException
		def initialize(mod)
			super("Unknown module: #{mod}", 404)
		end
	end

	class MissingIdException < HTTPException
		def initialize(id)
			super('Missing an id in the URI.', 412)
		end
	end

	class MissingParamsException < HTTPException
		def initialize(params)
			super('Missing parameters: ' + params.join(', '), 412)
		end
	end

	class InvalidResourceResultException < HTTPException
		def initialize
			super('Result should always be an Array', 500)
		end
	end

	class DataNotFoundException < HTTPException
		def initialize(fieldname, value)
			super("Could not find data for #{field}: #{value}", 200)
		end
	end

	class InvalidFilterException < HTTPException
		def initialize(index, msg)
			super("Filter error at character #{index}: #{msg}", 412)
		end
	end

	class InvalidAuthentication < HTTPException
		def initialize
			super('Invalid authentication', 401)
		end
	end

	class NoRightsException < HTTPException
		def initialize
			super('No rights to do this', 403)
		end
	end

	class UnknownObjectException < HTTPException
		def initialize(id = '')
			title = 'Unknown object'
			title += " ('#{id}')" if (id != '')
			super(title, 404)
		end
	end

	class UnknownObjectException < HTTPException
		def initialize(id = '')
			title = 'Unknown object'
			title += " ('#{id}')" unless id.empty?
			super(title)
		end
	end

	class NotImplementedException < HTTPException
		def initialize
			super('This method is not implemented, yet')
		end
	end

	class NotOverridenException < HTTPException
		def initialize
			super('This method should be overriden')
		end
	end

end