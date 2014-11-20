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

	# RedirectException doesn't use the HTTPException, but a regular exception instead.
	# Redirects are exceptions because clearly to current representation, doesn't fit.
	# However, it's not needed to classify this as an error.
	class RedirectException < Exception
		attr_reader :url, :code

		def initialize(url, redirect_code = 303)
			@url = url
			@code = redirect_code
			super("Please, redirect to #{url}")
		end
	end

end