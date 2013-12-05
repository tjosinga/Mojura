require 'webapp/mojura/lib/baseview'
require 'webapp/mojura/views/base_body'
require 'webapp/mojura/views/pageeditview'

module MojuraWebApp

	class PageView < BaseView

		attr_reader :request_uri, :request_params, :metatags, :links, :scripts, :script_links, :styles,
		            :templates, :locales, :locale, :pageid, :is_home

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
			@is_home = false
			@locale = Settings.get_s(:locale)
			super({})

			self.include_script_link('ext/jquery/jquery.min.js')
			self.include_script_link('ext/jquery/jquery-ui.min.js')
			self.include_script_link('ext/jquery/jquery.form.min.js')

			self.include_script_link('ext/bootstrap/js/bootstrap.min.js')
			self.include_style_link('ext/bootstrap/css/bootstrap.min.css')
			self.include_style_link('ext/font-awesome/css/font-awesome.min.css')

			self.include_script_link('ext/mustache/mustache.min.js')

			# Check for the generated Mojura JS file. Otherwise add each source
			mojura_js = "#{Mojura::PATH}/webapp/mojura/js/mojura.min.js"
			if File.exist?(mojura_js)
				self.include_script_link('mojura/js/mojura.min.js')
			else
				Dir.foreach("#{Mojura::PATH}/webapp/mojura/js/sources/") { |name|
					self.include_script_link("mojura/js/sources/#{name}") if name.end_with?('.js')
				}
			end
			self.include_style_link('mojura/css/style.min.css')
		end

		def load
			@pageid = nil
			@pageid = @request_uri if (@request_uri.match(/^[0-9a-f]{24}$/))

			if !@pageid.nil?
				@data = WebApp.api_call("pages/#{@pageid}")
				@is_home = (@pageid == Settings.get_s(:default_pageid))
			elsif !@request_uri.empty?
				begin
					pages = WebApp.api_call('pages', {path: @request_uri})
					@pageid = pages.last[:id]
					@data = WebApp.api_call("pages/#{@pageid}")
					@is_home = (@pageid == Settings.get_s(:default_pageid))
				rescue HTTPException => e
					filename = Mojura.filename("webapp/views/#{@request_uri}/view_main.rb")
					unless filename.nil?
						@data[:title] = Locale.str(@request_uri, :view_title)
						@data[:view] = @request_uri
					else
						@data[:title] = "'#{e.class}' for view #{@request_uri}" #titel from strings.locale.json
						@data[:view] = nil
						@data[:error] = e.to_s
					end
				end
			else
				@is_home = true
				@pageid = Settings.get_s(:default_pageid) # TODO: Select the default page from Settings
				if @pageid.empty?
					begin
						@pages = WebApp.api_call('pages')
						@pageid = @pages.first[:id] unless (@pages.nil? || @pages.first.nil?)
					rescue APIException => _
						@pages = {}
						@pageid = nil
					end
				end
				@data = (@pageid.empty?) ? nil : WebApp.api_call("pages/#{@pageid}")
			end
			@data = {view: 'setup', title: Locale.str('system', 'view_title')} if @data.nil? && WebApp.has_view('setup')
			@data = {view: 'sitemap', title: Locale.str('system', 'no_default_page')} if @data.nil?
			@data.symbolize_keys!
		end

		def title
			result = Settings.get_s(:title, :core, 'A Mojura website')
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
			@data[:description] || Settings.get_s('description', :core, 'Mojura is a fine API based Content Management System')
		end

		def get_best_url(filename)
			return filename if filename.include?('://')
			if Settings.get_b(:use_external_hosted_files)
				external = ExternalLibraries.get_external_equivalent(filename)
				return external unless external.empty?
			end

			if filename.end_with?('.min.js') || filename.end_with?('.min.css')
				return filename unless Mojura.filename("webapp/#{filename}").nil?
				normal_filename = filename.gsub(/\.min\.js$/, '.js').gsub(/\.min\.css$/, '.css')
				return normal_filename unless Mojura.filename("webapp/#{normal_filename}").nil?
			else
				minified_filename = filename.gsub(/\.js$/, '.min.js').gsub(/\.css$/, '.min.css')
				return minified_filename unless Mojura.filename("webapp/#{minified_filename}").nil?
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
			script_url = get_best_url(script_url)
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
			style_url = get_best_url(style_url)
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
			filename = "#{Mojura::PATH}/#{filename}" unless File.exist?(filename)
			self.include_template(id, File.read(filename))
		end

		def include_locale(view)
			Locale.strings(view).each{ | id, val |
				@locales.push({view: view, id: id, str: val})
			}
		end

		def render
			# preloading so all views can still affect the page object (i.e. to include css, js, etc.)
			self.include_template_file('modal_template', 'webapp/mojura/views/modal.mustache')

			if File.exists?('webapp/views/body/view_main.rb')
				require 'webapp/views/body/view_main'
				@body_html = WebApp.render_view(:view => 'body', :wrapping => 'simple', :classes => 'body_container', :add_span => false)
			else
				@body_html = BaseBodyView.new({}).render
			end
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