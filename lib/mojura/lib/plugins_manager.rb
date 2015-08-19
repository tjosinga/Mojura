module Mojura

	module PluginsManager
		extend self

		@plugins = []

		def register(path)
			@plugins.push(path)
		end

		def get_plugin_paths
			return @plugins.clone
		end

	end

end