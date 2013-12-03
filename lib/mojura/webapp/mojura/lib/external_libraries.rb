require 'kvparser'

module MojuraWebApp

	module ExternalLibraries
		extend self

		private

		@libs = {}

		public

		def load
			filename = Mojura.filename('webapp/ext/external_hosting.kv')
			@libs = KeyValueParser.parse(File.read(filename))
		end

		def get_external_equivalent(local_file)
			return @libs[local_file.to_sym] || ''
		end

	end

end