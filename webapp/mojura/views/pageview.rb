require 'webapp/mojura/lib/baseview'
require 'webapp/mojura/views/pageeditview'

module MojuraWebApp

	class PageView < BaseView

		attr_reader :request_uri, :request_params, :metatags, :links, :scripts, :script_links, :styles,
		            :templates, :locales, :locale, :pageid

		def initialize(uri = '', params = {})
			@request_uri = uri
			@request_params = params
			@metatags = []
			@links = []
			@scripts = []
			@script_links = []
			@styles = []
			@templates = []
			@locales = []
			@data = {}
			@body_html = ''
			@locale = Settings.get_s(:locale)
			super({})

			if Settings.get_b(:use_external_js_libs)
				self.include_script_link('https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js')
				self.include_script_link('https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.21/jquery-ui.min.js')
				self.include_script_link('http://malsup.github.com/jquery.form.js')
			else
				self.include_script_link('ext/jquery/jquery.min.js')
				self.include_script_link('ext/jquery/jquery-ui.min.js')
				self.include_script_link('ext/jquery/jquery.form.min.js')
			end

			self.include_style_link('//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.no-icons.min.css')
			self.include_style_link('//netdna.bootstrapcdn.com/font-awesome/3.2.0/css/font-awesome.css')
			self.include_script_link('//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/js/bootstrap.min.js')

			self.include_script_link('ext/mustache/mustache.min.js')

			self.include_script_link('mojura/js/validator.min.js')
			self.include_script_link('mojura/js/kvparser.min.js')
			self.include_script_link('mojura/js/locale.min.js')
			self.include_style_link('mojura/css/style.min.css')

		end

		def load
			@pageid = nil
			@pageid = @request_uri if (@request_uri.match(/^[0-9a-f]{24}$/))

			if !@pageid.nil?
				@data = WebApp.api_call("pages/#{@pageid}")
			elsif @request_uri != ''
				begin
					pages = WebApp.api_call('pages', {path: @request_uri})
					@pageid = pages.last[:id]
					@data = WebApp.api_call("pages/#{@pageid}")
				rescue HTTPException => e
					if File.exists?("webapp/views/#{@request_uri}/view_main.rb")
						@data[:title] = Locale.str(@request_uri, :view_title)
						@data[:view] = @request_uri
					else
						@data[:title] = "'#{e.class}' for view #{@request_uri}" #titel from strings.locale.json
						@data[:view] = nil
						@data[:error] = e.to_s
					end
				end
			else
				@pageid = nil # TODO: Select the default page from Settings
				if @pageid.nil?
					begin
						@pages = WebApp.api_call('pages')
						@pageid = @pages.first[:id] unless (@pages.nil? || @pages.first.nil?)
					rescue APIException => _
						@pages = {}
						@pageid = nil
					end
				end
				@data = (@pageid.nil?) ? nil : WebApp.api_call("pages/#{@pageid}")
			end
			@data = {view: 'sitemap', title: Locale.str('system', 'no_default_page')} if @data.nil?
			@data.symbolize_keys!
		end

		def title
			result = Settings.get_s(:title)
			result += ' - ' + @data[:title] if (@data.include?(:title)) && (@data[:title] != '')
			return result
		end

		def title=(str)
			@data[:title] = str
		end

		def base_url
			WebApp.web_url
		end

		def description
			@data[:description] || Settings.get_s('description', 'Mojura is a fine API based Content Management System')
		end

		def get_minified_or_original(filename)
			return filename if filename.include?('://')
			if filename.end_with?('.min.js') || filename.end_with?('.min.css')
				return filename if File.exists?("webapp/#{filename}")
				normal_filename = filename.gsub(/\.min\.js$/, '.js').gsub(/\.min\.css$/, '.css')
				return normal_filename if File.exists?("webapp/#{normal_filename}")
			else
				minified_filename = filename.gsub(/\.js$/, '.min.js').gsub(/\.css$/, '.min.css')
				return minified_filename if File.exists?("webapp/#{minified_filename}")
			end
			return filename
		end

		def include_metatag(name, content)
			in_dict = false
			@scripts.each { |v|
				if v[:name] == name
					in_dict = true
					v[:content] = content
				end
			}
			@metatags.push({name: 'name', content: content}) if !in_dict
		end

		def include_link(rel, type, href, title = '')
			in_dict = false
			@links.each { |v| in_dict = true if v[:href] == href }
			@links.push({rel: rel, type: type, href: href, title: title}) if !in_dict
		end

		def include_script(code)
			@scripts.push({code: code})
		end

		def include_script_link(script_url)
			script_url = get_minified_or_original(script_url)
			in_dict = false
			@script_links.each { |v| in_dict = true if v[:script] == script_url }
			@script_links.push({script: script_url}) if !in_dict
		end

		def include_style(style)
			in_dict = false
			@scripts.each { |v| in_dict = true if v[:style] == style }
			@styles.push({style: style}) if !in_dict
		end

		def include_style_link(style_url)
			style_url = get_minified_or_original(style_url)
			self.include_link('stylesheet', 'text/css', style_url)
		end

		def include_template(id, code)
			self.include_script_link('ext/mustache/mustache.min.js')
			code.gsub!(/\{\{locale_str_([0-9a-zA-Z]+)_(\w+)\}\}/) { |str|
				view, str_id = str.gsub(/(\{\{locale_str_|\}\})/, '').split('_', 2)
				Locale.str(view.to_sym, str_id.to_sym)
			}
			code.gsub!(/\{\{base_url\}\}/, WebApp.page.request_uri)
			@templates.push({id: id, template: code})
		end

		def include_template_file(id, filename)
			self.include_template(id, File.read(filename))
		end

		def include_locale(view)
			Locale.strings(view).each{ | id, val |
				@locales.push({view: view, id: id, str: val})
			}
		end

		def render
			# preloading so all views can still affect the page object (i.e. to include css, js, etc.)
			require 'webapp/views/body/view_main'
			@body_html = WebApp.render_view(:view => 'body', :wrapping => 'simple', :classes => 'body_container', :add_span => false)
			super
		end

		def body
			@body_html
		end

		def has_analyticsid
			!Settings.get_s(:analyticsid).empty?
		end

		def analyticsid
			Settings.get_s(:analyticsid)
		end

	end

end