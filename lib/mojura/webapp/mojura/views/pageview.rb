require 'webapp/mojura/lib/baseview'
require 'webapp/mojura/views/base_body'
require 'webapp/mojura/views/pageeditview'

module MojuraWebApp

	class PageView < BaseView

		attr_reader :request_uri, :request_params, :metatags, :links, :scripts, :script_links, :styles,
		            :templates, :locales, :pageid, :is_home, :is_setup

		attr_accessor :favicon, :status

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
			@is_setup = false
			@favicon = 'mojura/images/favicon.ico'
			@status = 200
			@cache_urls = {}
			super({})

			self.include_style_link('ext/font-awesome/css/font-awesome.min.css')
			self.include_style_link('ext/bootstrap/css/bootstrap.min.css')
			self.include_style_link('mojura/css/style.min.css')

			self.include_script_link('ext/jquery/jquery.min.js')
			self.include_script_link('ext/jquery/jquery.form.min.js')
			self.include_script_link('ext/bootstrap/js/bootstrap.min.js')
			self.include_script_link('ext/mustache/mustache.min.js')
			self.include_script_link('ext/respond/respond.min.js')

			# Check for the generated Mojura JS file. Otherwise add each source
			mojura_js = "#{Mojura::PATH}/webapp/mojura/js/mojura.min.js"
			if File.exist?(mojura_js) && !Settings.get_b(:developing)
				self.include_script_link('mojura/js/mojura.min.js')
			else
				Dir.foreach("#{Mojura::PATH}/webapp/mojura/js/sources/") { |name|
					self.include_script_link("mojura/js/sources/#{name}") if name.end_with?('.js')
				}
			end
		end

		def default_pageid
			result = Settings.get_s("default_pageid_#{WebApp.locale}".to_sym)
			result = Settings.get_s(:default_pageid) if (result.empty?)
			return result
		end

		def url_of_page(pageid)
			return '' if pageid.to_s.empty?
			return @cache_urls[pageid] if @cache_urls.include?(pageid)
			parents = WebApp.api_call('pages', {path_pageid: pageid})
			result = parents.map{ | p | CGI.escape(p[:title]) }.join('/')
			@cache_urls[pageid] = result
			return result
		end

		def is_root_page?(pageid)
			return WebApp.multilingual? ? !locale_of_root_page(pageid).nil? : pageid.nil?
		end

		def locale_of_root_page(pageid)
			return Settings.get_s(:locale).to_sym if pageid.nil? || !WebApp.multilingual?
			supported_locales = Settings.get_a(:supported_locales, :core, [])
			supported_locales.each { | locale |
				return locale.to_sym if (pageid == Settings.get_s("root_pageid_#{locale}".to_sym))
			}
			return nil
		end

		def root_url
			return url_of_page(Settings.get_s("root_pageid_#{WebApp.locale}".to_sym))
		end

		def load
			@pageid = nil
			@pageid = @request_uri if (@request_uri.match(/^[0-9a-f]{24}$/))

			if !@pageid.nil?
				@data = WebApp.api_call("pages/#{@pageid}")
				@is_home = (@pageid == default_pageid)
			elsif !@request_uri.empty?
				begin
					pages = WebApp.api_call('pages', {path: @request_uri, auto_set_locale: true})
					@pageid = pages.last[:id]
					if is_root_page?(pageid)
						WebApp.locale = locale_of_root_page(pageid)
						pid = default_pageid
						url = (pid.empty?) ? base_url : base_url.gsub(/\/$/, '') + '/' + url_of_page(pid)
						raise RedirectException.new(url) unless (pageid == pid)
					else
						pages.reverse_each { | page |
							if (is_root_page?(page[:id]))
								WebApp.locale = locale_of_root_page(page[:id])
								break
							end
							WebApp.locale = Settings.get_s(:locale).to_sym
						}
					end
					@data = WebApp.api_call("pages/#{@pageid}")
					@is_home = (@pageid == default_pageid)
				rescue HTTPException => e
					filename = Mojura.filename("webapp/views/#{@request_uri}/view_main.rb")
					unless filename.empty?
						@data[:title] = Locale.str(@request_uri, :view_title)
						@data[:view] = @request_uri
					else
						@status = 404
						@data[:title] = Locale.str(:system, :error) + ' 404'
						@data[:view] = nil
						@data[:error] = @request_uri
					end
				end
			else
				@is_home = true
				WebApp.locale = Settings.get_s(:locale) if WebApp.multilingual?
				@pageid = default_pageid
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
			@is_setup = (@data.nil? || (@data[:view] == 'setup')) && WebApp.has_view('setup')
			@data = {view: 'setup', title: Locale.str('setup', 'view_title')} if @is_setup
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

			minified_filename = filename
			normal_filename = filename
			if filename.end_with?('.min.js') || filename.end_with?('.min.css')
				normal_filename = filename.gsub(/\.min\.js$/, '.js').gsub(/\.min\.css$/, '.css')
			else
				minified_filename = filename.gsub(/\.js$/, '.min.js').gsub(/\.css$/, '.min.css')
			end
			normal_filename = minified_filename unless File.exists?(Mojura.filename("webapp/#{normal_filename}"))
			minified_filename = normal_filename unless File.exists?(Mojura.filename("webapp/#{minified_filename}"))
			return Settings.get_b(:developing) ? normal_filename : minified_filename
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
			if id == 'template-rights-controls' && Settings.get_b(:advanced_rights_control)
				%w(advanced_object_rights advanced_object_rights_users advanced_object_rights_groups).each { | name |
					@templates.push({id: 'template-' + name.gsub('_', '-'), template: File.read("#{Mojura::PATH}/webapp/mojura/modals/#{name}.mustache")})
				}
			end
			code.gsub!(/\{\{locale_str_([0-9a-zA-Z]+)_(\w+)\}\}/) { |str|
				view, str_id = str.gsub(/(\{\{locale_str_|\}\})/, '').split('_', 2)
				Locale.str(view.to_sym, str_id.to_sym)
			}
			code.gsub!(/\{\{base_url\}\}/, WebApp.page.request_uri)
			@templates.push({id: id, template: code})
		end

		def include_template_file(id, filename)
			file = Mojura.filename(filename)
			if file.empty?
				WebApp.log.warn("include_template_filename: '#{filename}' does not exists");
			else
				self.include_template(id, File.read(file))
			end
		end

		def include_locale(view)
			Locale.strings(view).each{ | id, val |
				@locales.push({view: view, id: id, str: val})
			}
		end

		# @deprecated
		def set_favicon(relative_path)
			@favicon = relative_path
		end

		def render
			# preloading so all views can still affect the page object (i.e. to include css, js, etc.)
			self.include_locale(:system)
			self.include_template_file('template-modal', 'webapp/mojura/modals/modal.mustache')
			self.include_template_file('template-alert', 'webapp/mojura/modals/alert.mustache')
			self.include_template_file('template-lightbox', 'webapp/mojura/modals/lightbox.mustache')
			if (WebApp.current_user.logged_in?)
				type = Settings.get_b(:advanced_rights_control) ? 'advanced' : 'simple'
				self.include_template_file('template-rights-controls', "webapp/mojura/modals/rights_controls_#{type}.mustache")
			end

			if File.exists?('webapp/views/body/view_main.rb')
				require 'webapp/views/body/view_main'
				@body_html = WebApp.render_view(:view => 'body', :wrapping => 'nowrap', :add_span => false)
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

		def is_404
			@status == 404
		end

		def locale
			WebApp.locale
		end

		def locale_default_urls
			result = [{ locale: WebApp.locale, url: url_of_page(default_pageid)}] unless WebApp.multilingual?
			result = []
			Settings.get_a(:supported_locales).each { | locale |
				url = url_of_page(Settings.get_s("default_pageid_#{locale}".to_sym))
				result.push({ locale: locale, url: url })
			}
			return result
		end

	end

end