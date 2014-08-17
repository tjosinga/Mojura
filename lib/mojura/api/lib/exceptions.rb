module MojuraAPI

	class HTTPException < Exception
		attr_reader :code

		def initialize(error_string, error_code = 500)
			@code = error_code
			API.log.error(error_string) rescue ''
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

	class ResourceNotFoundException < HTTPException
		def initialize(path = '')
			path = API.current_call if path.empty?
			super("There's no resouce found at #{path}", 404)
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

	class DependencyException < HTTPException
		def initialize(mod, needed_mod)
			super("Module #{mod} needs #{needed_mod}")
		end
	end

	class DependencyVersionException < HTTPException
		def initialize(mod, needed_mod, needed_version, real_version)
			super("Module #{mod} needs version #{needed_version} of #{needed_mod}, but found version #{real_version}")
		end
	end

	class NotAllowedSettingException < HTTPException
		def initialize(setting, category = :core)
			super("You're not allowed to set the setting #{category}::#{setting}", 403)
		end
	end

	class SMSDestinationException < HTTPException
		def initialize(dest)
			super("The mobile text destination (#{dest}) is invalid")
		end
	end

	class SMSInvalidConfiguration < HTTPException
		def initialize(service)
			super("The SMS text service #{service} isn't configured correctly")
		end
	end

	class SMSSendException < HTTPException
		def initialize(dest)
			super("The SMS text message to #{dest} failed")
		end
	end

end