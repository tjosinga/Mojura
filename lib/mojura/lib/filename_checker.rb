module Mojura
	extend self

	STDOUT << "Loading file manager\n"

	PATH = File.expand_path(File.dirname(__FILE__) + "/..")
	STDOUT << "Path: #{PATH}\n"

	# Checks wether the given filename is available in the project or the gem and returns the correct filename.
	# Returns an empty string if the file does not exists.
	def filename(filename)
		if File.exists?(filename)
			return filename
		elsif File.exists?("#{PATH}/#{filename}")
			return "#{PATH}/#{filename}"
		else
			PluginsManager.get_plugin_paths.each { | path |
				return "#{path}/#{filename}" if File.exists?("#{path}/#{filename}")
			}
			return ''
		end
	end

end