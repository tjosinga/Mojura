module MojuraWebApp

	# noinspection RubyConstantNamingConvention
	HTTPException = MojuraAPI::HTTPException

	class UnknownViewException < HTTPException
		def initialize(view)
			super("Unknown view '#{view}'. Probably the view hasn't been registered to the WebApp.", 404)
		end
	end

	class CorruptViewFileException < HTTPException
		def initialize(view, message)
			super("Could not load view file of #{view} - #{message}", 500)
		end
	end

	class CorruptStringsFileException < HTTPException
		def initialize(view, message)
			super("Could not load strings file of: #{view} - #{message}", 500)
		end
	end

	class CorruptMustacheException < HTTPException
		def initialize(view, message)
			super("Could not load mustache file of: #{view} - #{message}", 500)
		end
	end

	class APIException < HTTPException
		def initialize(call, method, message)
			super("An API error occured while sending '#{method.upcase}: #{call}'. The error said: '#{message}'")
		end
	end

end