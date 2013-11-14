require 'kvparser'

module MojuraWebApp

	module ExternalLibraries
		extend self

		private

		@libs = {}

		public

		def load
			filename = 'webapp/ext/external_hosting.kv'
			filename = "#{Mojura::PATH}/#{filename}" unless File.exist?(filename)
			@libs = KeyValueParser.parse(File.read(filename))
		end

		def get_external_equivalent(local_file)
			return @libs[local_file.to_sym] || ''
		end

	end

end