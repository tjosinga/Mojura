require 'log4r'
require 'webapp/mojura/lib/exceptions'
require 'webapp/mojura/lib/baseview'
require 'webapp/mojura/lib/settings'
require 'webapp/mojura/lib/locale'
require 'webapp/mojura/lib/external_libraries'
require 'webapp/mojura/views/viewwrapper'
require 'webapp/mojura/views/pageview'

module MojuraWebApp

	module WebApp

		# Convert module to singleton
		extend self

		@settings = {}
		@new_settings = {}
		@view_classes = {}
		@strings = {}

		attr_reader :log, :loaded

		def render(uri = '', params = {})
			load
			params.symbolize_keys!
			WebApp.log.debug("New page call: '#{uri}' with params #{params}")
			Thread.current[:mojura][:page] = PageView.new(uri, params)
			Thread.current[:mojura][:page].load
			result = Thread.current[:mojura][:page].render
			WebApp.save_settings if (@new_settings.count > 0)
			return result
		end

		# ------------------------------------------------- Initialization -------------------------------------------------

		def load
			return if @loaded
			@loaded = true
			@log = Log4r::Logger.new('WebApp')
			@log.add(Log4r::Outputter.stdout)
			@log.info('----- Loading the WebApp -----')
			WebApp.load_views
			ExternalLibraries.load
			@log.info('----- The WebApp is loaded -----')
		end

		def load_views
			path = 'webapp/views/'
			Dir.foreach(path) { |name|
				if (name != '.') && (name != '..') && (File.directory?(path + name))
					WebApp.log.info("Loading view #{name}")
					filename = path + name + '/view_main.rb'
					require filename if File.exists?(filename)
				end
			}
		end

		def load_cdns

		end

		# ------------------------------------------------ Thread Shortcuts ------------------------------------------------

		def init_thread(env = [])
			load
			port = env['SERVER_PORT'].to_i
			port_str = ((port != 80) && (port != 443)) ? ':' + port.to_s : ''
			Thread.current[:mojura] ||= {}
			Thread.current[:mojura][:webapp_headers] = {}
			Thread.current[:mojura][:web_url] = env['rack.url_scheme'].to_s + '://' + env['SERVER_NAME'] + port_str + '/'
		end

		# @return [PageView]
		def page
			Thread.current[:mojura][:page]
		end

		def web_url
			Thread.current[:mojura][:web_url]
		end

		def headers
			Thread.current[:mojura][:webapp_headers]
		end

		def headers=(hdrs)
			Thread.current[:mojura][:webapp_headers] = hdrs
		end

		# ------------------------------------------------------- API ------------------------------------------------------

		def api_call(command, params = {}, method = 'get')
			begin
				MojuraAPI::API.call(command, params, method)
#			rescue Exception => e
#				raise APIException.new(command, method, e.to_s)
			end
		end

		def current_user
			MojuraAPI::API.current_user
		end

		def parse_text(text, markup = :ubb)
			MojuraAPI::RichText.new(text, markup).to_html
		end

		def realm
			MojuraAPI::Settings.get_s(:realm)
		end

		# ------------------------------------------------------ Views -----------------------------------------------------

		def register_view(view_id, view_class, options = {})
			WebApp.log.info("Registering view #{view_id}")
			options[:in_pages] = true if (options[:in_pages].nil?)
			@view_classes[view_id] = {view_id: view_id,
			                          class: view_class,
			                          in_pages: options[:in_pages],
			                          min_col_span: options[:min_col_span] || 1 }
		end

		def get_view_class(view_id)
			@view_classes[view_id][:class] rescue nil
		end

		def render_view(options = {})
			begin
				ViewWrapper.new(options).render
			rescue Exception => e
				"Error on rendering: #{e.to_s}"
			end
		end

		def get_views(only_in_pages = true)
			result = []
			@view_classes.each { |_, data|
				result.push(data.clone) if (!only_in_pages) || ((data.include?(:in_pages) && data[:in_pages]))
			}
			result.sort! { |t1, t2| t1[:title] <=> t2[:title] }
			return result
		end

		# ----------------------------------------------------- Strings ----------------------------------------------------

		def locale_str(view, id, options = {})
			Locale.str(view, id, options)
		end

	end

end

