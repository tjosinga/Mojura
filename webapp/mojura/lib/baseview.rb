require 'mustache'
require 'webapp/mojura/lib/editor'

module MojuraWebApp

	class BaseView < Mustache

		attr_reader :options, :data

		def initialize(options = {}, data = {})
			@data = data
			@data = {} if (!data.is_a?(Hash))
			@options = options
			if @options[:uses_editor]
				WebApp.page.include_script_link('ext/sceditor/jquery.sceditor.min.js')
				WebApp.page.include_style_link('ext/sceditor/themes/default.min.css')
			end
			source_file        = self.method(methods[0]).source_location[0]
			self.template_path = source_file.gsub(/\w*.rb$/, '')
			self.template_file = source_file.gsub(/\.rb$/, '.mustache')
			self.on_init if (self.respond_to?(:on_init))
		end

		# noinspection RubyUnusedLocalVariable
		def method_missing(name, *arguments)
			result = nil
			name   = name.to_s
			if name.match(/^app_str_/)
				view, id = name.match(/^app_str_([0-9a-zA-Z]*)_(\w*)$/).captures
				result   = WebApp.app_str(view, id)
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
			super || method.match(/^app_str_/) || @data.has_key?(method.to_sym) || @data.has_key?(method.to_s)
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