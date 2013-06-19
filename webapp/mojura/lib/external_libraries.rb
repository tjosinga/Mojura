require 'kvparser'

module MojuraWebApp

	module ExternalLibraries
		extend self

		private

		@libs = {}

		public

		def load
			@libs = KeyValueParser.parse(File.read('webapp/ext/external_hosting.kv'))
		end

		def get_external_equivalent(local_file)
			return @libs[local_file.to_sym] || ''
		end

	end

end