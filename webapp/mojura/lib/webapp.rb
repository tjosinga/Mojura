require 'webapp/mojura/lib/exceptions'
require 'webapp/mojura/lib/baseview'
require 'webapp/mojura/views/viewwrapper'
require 'webapp/mojura/views/pageview'

module MojuraWebApp

	module WebApp

		@@settings = {}
		@@new_settings = {}
		@@view_classes = {}
		@@strings = {}

		def self.render(uri = '', params = {})
			params.symbolize_keys!
			Thread.current[:mojura][:page] = PageView.new(uri, params)
			Thread.current[:mojura][:page].load
			WebApp.load_settings if (@@settings.count == 0)
  		WebApp.load_views
			result = Thread.current[:mojura][:page].render
			WebApp.save_settings if (@@new_settings.count > 0)
			return result
		end

		# ------------------------------------------------ Thread Shortcuts --------------------------------------------------

  	def self.init_thread(env = [])
      port = env['SERVER_PORT'].to_i
      port_str = ((port != 80) && (port != 443)) ? ':' + port.to_s : ''
      Thread.current[:mojura] ||= {}
			Thread.current[:mojura][:webapp_headers] = {}
			Thread.current[:mojura][:web_url] = env['rack.url_scheme'].to_s + '://' + env['SERVER_NAME'] + port_str + '/'
		end

		def self.page
			Thread.current[:mojura][:page]
		end

		def self.web_url
			Thread.current[:mojura][:web_url]
		end

  	def self.headers
  		Thread.current[:mojura][:webapp_headers]
  	end

  	def self.headers=(hdrs)
  		Thread.current[:mojura][:webapp_headers] = hdrs
  	end


		# ------------------------------------------------------- API --------------------------------------------------------

		def self.api_call(command, params = {}, method = 'get')
			begin
				MojuraAPI::API.call(command, params, method)
			rescue Exception => e
				raise APIException.new(command, method, e.to_s)
			end
		end

		def self.current_user
			MojuraAPI::API.current_user
		end

		def self.parse_text(text, markup = :ubb)
			MojuraAPI::RichText.new(text, markup).to_html
		end

		def self.settings
		  MojuraAPI::API.settings
		end

		def self.realm
			MojuraAPI::API.settings[:project]
		end

		# ------------------------------------------------------ Views -------------------------------------------------------

		def self.register_view(view_id, view_class, options = {})
			options[:in_pages] = true if (options[:in_pages].nil?)
			@@view_classes[view_id] = {view_id: view_id,
                                 class: view_class,
                                 in_pages: options[:in_pages],
                                 min_col_span: options[:min_col_span] || 1,
                                 title: options[:title] || WebApp.app_str(view_id, 'view_title')}
		end

		def self.get_view_class(view_id)
			@@view_classes[view_id][:class] rescue nil
		end

		def self.render_view(options = {})
			begin
				STDOUT << "Rendering #{options[:view]}\n"
				ViewWrapper.new(options).render
			rescue Exception => e
				"Error on rendering: #{e.to_s}"
			end
		end

		def self.load_views
			path = 'webapp/views/'
      Dir.foreach(path) { | name |
	      if (name != '.') && (name != '..') && (File.directory?(path + name))
	      	filename = path + name + '/view_main.rb'
	      	require filename if File.exists?(filename)
	      end
      }
		end

		def self.get_views(only_in_pages = true)
			result = []
			@@view_classes.each { | _, data |
				result.push(data.clone) if (!only_in_pages) || ((data.include?(:in_pages) && data[:in_pages]))
			}
			result.sort! { | t1, t2 | t1[:title] <=> t2[:title] }
			return result
		end

		# ----------------------------------------------------- Settings -----------------------------------------------------

		def self.get_setting(setting, default = '', module_name = 'core')
			return @@settings.has_key?(module_name) ? @@settings[module_name][setting] : default
		end

		def self.set_setting(setting, value, module_name = 'core')
			@@settings[module_name] = {} if !@@settings.has_key?(module_name)
			@@settings[module_name][setting] = value

			@@new_settings[module_name] = {} if !@@new_settings.has_key?(module_name)
			@@new_settings[module_name][setting] = value
		end

		def self.load_settings
			# load from api
		end

		def self.save_settings
			# Only saves new settings
			# save to api
		end

		# ----------------------------------------------------- Strings ------------------------------------------------------

		def self.load_app_strings(view, locale = nil)
			view = view.to_sym
			locale ||= self.page.locale
      begin
				strings_file = case view
					when :system then "webapp/mojura/views/strings.#{locale}.json"
					when :view_template_names then "webapp/mojura/views/strings_view_template_names.#{locale}.json"
					else "webapp/views/#{view}/strings.#{locale}.json"
				end
 				@@strings[self.page.locale] ||= {}
 				@@strings[self.page.locale][view] = JSON.parse(File.read(strings_file)) if (File.exists?(strings_file))
			rescue Exception => e
				raise CorruptStringsFileException.new(view, e.to_s)
			end
		end

		def self.app_str(view, id, options = {})
			locale = options[:locale] || self.page.locale
      view = view.to_sym
			@@strings[locale] ||= {}
			self.load_app_strings(view) if (!@@strings[locale].include?(view))
			@@strings[locale][view] ||= {}
			return (@@strings[locale][view][id.to_s] || options[:default] || "__#{view}_#{id}__")
		end

	end

end

