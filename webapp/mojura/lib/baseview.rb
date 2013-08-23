require 'mustache'

module MojuraWebApp

	class BaseView < Mustache

		attr_reader :options, :data, :source_file

		def initialize(options = {}, data = {})
			@data = data
			@data = {} if (!data.is_a?(Hash))
			@options = options
			if @options[:uses_editor]
				WebApp.page.include_script_link('ext/jquery/jquery-textrange.min.js')
			end
			if private_methods(false).include?(:initialize)
				source_file = method(:initialize).source_location[0]
			elsif public_methods(false).include?(:render)
				source_file = method(:initialize).source_location[0]
			else
				source_file = caller.first.split(':')[0]
			end

			self.template_path = source_file.gsub(/\w*.rb$/, '')
			self.template_file = source_file.gsub(/\.rb$/, '.mustache')
			self.on_init if (self.respond_to?(:on_init))
		end

		# noinspection RubyUnusedLocalVariable
		def method_missing(name, *arguments)
			result = nil
			name = name.to_s
			if name.match(/^locale_str_/)
				view, id = name.match(/^locale_str_([0-9a-zA-Z]*)_(\w*)$/).captures
				result = Locale.str(view, id)
			elsif @data.has_key?(name.to_s)
				result = @data[name.to_s]
			elsif @data.has_key?(name.to_sym)
				result = @data[name.to_sym]
			end
			return result
		end

		def base_url
			WebApp.page.request_uri
		end

		def respond_to?(method)
			super || method.match(/^locale_str_/) || @data.has_key?(method.to_sym) || @data.has_key?(method.to_s)
		end

		def partial(name)
			# Original seems buggy somehow. Doing it myself by reading the correct file.
			File.read("#{self.template_path}/#{name}.#{self.template_extension}")
		end

		def pretty_data
			'<pre>' + JSON.pretty_generate(@data) + '</pre>'
		end

		def pretty_options
			'<pre>' + JSON.pretty_generate(@options) + '</pre>'
		end

	end

end