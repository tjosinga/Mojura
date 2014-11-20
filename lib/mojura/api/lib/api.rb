# This file contains the Mojura API module.
# Author:: Taco Jan Osinga, Osinga Software
# Website:: www.mojura.nl

require 'fileutils'
require 'openssl'
require 'digest/md5'
require 'yaml'
require 'log4r'
require 'api/lib/mongodb'
require 'api/lib/exceptions'
require 'api/lib/ubbparser_additions'
require 'api/lib/settings'
require 'api/lib/access_control'
require 'api/resources/locale/locale.object'
require 'api/resources/users/users.objects'
require 'api/resources/pages/pages.objects'

module MojuraAPI

	# The API module is the core of all data handling of Mojura. All data logic is and should be
	# implemented in this API and never in the WebApp. The WebApp should be considered as one
	# of the possible clients.
	module API

		# Convert this module to a singleton
		extend self

		# Module instances used for internal use. Some variables are accesible via identical named methods
		@modules = nil
		@resources = {}
		@loaded = false
		@first_init = true
		@log = nil
		@version = `gem spec mojura version`[/(\d+.\d+.\d+)/]

		# Loads all settings, resources and makes the connection with the database
		def load
			return if (@loaded)
			@log = Log4r::Logger.new('API')
			@log.add(Log4r::Outputter.stdout)
			@log.info('----- Loading the API -----')
			MongoDb.connect(Settings.get_s(:database))
			self.load_resources("#{Mojura::PATH}/api/resources/")
			self.load_resources('api/resources/') if (Dir.exist?('api/resources/'))
			AccessControl.load
			@log.info('----- The API is loaded -----')
			@loaded = true
		end

		# Initialize the current thread with thread-specific information, mainly form the request data.
		# Each thread equalizes one request. Thread handling is done soly by this API module.
		def init_thread(env = {})
			self.load
			req = Rack::Request.new(env)
			if !req.params['set-locale'].to_s.empty? && Settings.get_a(:supported_locales, :core, []).include?(req.params['set-locale'])
				env['rack.session']['locale'] = req.params['set-locale']
			end
			Thread.current[:mojura] = {} if Thread.current[:mojura].nil?
			Thread.current[:mojura][:env] = env || {}
			Thread.current[:mojura][:api_headers] = {}
			Thread.current[:mojura][:api_url] = (env['api_url'] || 'http://localhost/')
			Thread.current[:mojura][:locale] = env['rack.session']['locale'] || Settings.get_s('locale')

			uid = env['rack.session'].include?(:uid) ? env['rack.session'][:uid] : nil

			Thread.current[:mojura][:current_user] = nil # make sure the current is nil
			cookies = env['rack.request.cookie_hash']
			if (uid.nil?) && (cookies.include?('username')) && (cookies.include?('token'))
				token = cookies['token']
				username = cookies['username']
				users = Users.new({username: username}, :ignore_rights => true)
				if (users.count == 1) && (users.first.valid_cookie_token?(token))
					API.log.info("Authenticated #{username} using a cookie token")
					user = users.first
					user.generate_new_cookie_token
					Thread.current[:mojura][:current_user] = user
				else
					API.log.debug("Cookie found for #{username}, but couldn't authenticate")
				end
			end
			Thread.current[:mojura][:current_user] ||= User.new(uid)
			Locale.load_strings

			if @first_init
				@first_init = false
				if (Settings.get_s(:last_maintained_version) != @version)
					@log.info('----- Running maintenance jobs -----')
					self.maintenance({})
					@log.info('----- Finished maintenance jobs -----')
					Settings.set(:last_maintained_version, @version)
				end
			end
		end

		# Returns the current user.
		# @return [User]
		def current_user
			Thread.current[:mojura][:current_user]
		end

		# Returns the used API url.
		def api_url
			Thread.current[:mojura][:api_url]
		end

		# Returns all headers for the response.
		def headers
			Thread.current[:mojura][:api_headers]
		end

		# Sets all headers for the response.
		def headers=(hdrs)
			Thread.current[:mojura][:api_headers] = hdrs
		end

		# Returns all session variables in a hash.
		def session
			Thread.current[:mojura][:env]['rack.session']
		end

		def locale
			Thread.current[:mojura][:locale].to_sym
		end

		def locale=(loc)
			loc = loc.to_s
			return if (Thread.current[:mojura][:locale] == loc)
			supported_locales = Settings.get_a(:supported_locales, :core, [])
			return if (supported_locales.size <= 1) || !supported_locales.include?(loc)
			Thread.current[:mojura][:locale] = loc
			Thread.current[:mojura][:env]['rack.session']['locale'] = loc
			Locale.load_strings
		end

		def multilingual?
			unless Thread.current[:mojura].include?(:multilingual)
				Thread.current[:mojura][:multilingual] = (Settings.get_a(:supported_locales, :core, []).size > 1)
			end
			Thread.current[:mojura][:multilingual]
		end

		# Returns the ip address of the client
		def remote_ip
			Thread.current[:mojura][:env]['REMOTE_ADDR']
		end

		def current_call
			Thread.current[:mojura][:current_call]
		end

		def log
			@log
		end

		# Prepares the response headers for returning a file instead of text.
		def send_file(file_path, options = {})
			filename = options[:filename] || File.basename(file_path)
			options[:mime_type] ||= 'application/octet-stream'
			style = options[:style]
			style ||= 'inline' if (options[:mime_type][0..5] == 'image/')
			style ||= 'attachement'
			self.headers['X-Accel-Redirect'] = '/' + file_path
			self.headers['Content-Type'] = options[:mime_type]
			self.headers['Content-Disposition'] = "#{style}; filename='#{filename}'"
			return {to_path: file_path, options: options}
		end

		def load_module(mod)
			filename = (mod == :core) ? 'api/lib/settings.yml' : "api/resources/#{mod}/settings.yml"
			filename = Mojura.filename(filename)
			yaml = filename.empty? ? {} : YAML.load_file(filename)
			yaml.symbolize_keys!
			options = {ignore_if_exists: true, type: :file}
			Settings.set(:version, (yaml[:version] || '0.0.0'), mod, :private, options)
			Settings.set(:object_rights, yaml[:object_rights], mod, :protected, options) if yaml[:object_rights].is_a?(Hash)
			Settings.set(:maintenance, yaml[:maintenance], mod, :protected, options) if yaml[:maintenance].is_a?(Hash)
			yaml[:private].each { |k, v| Settings.set(k, v, mod, :private, options) } if yaml[:private].is_a?(Hash)
			yaml[:protected].each { |k, v| Settings.set(k, v, mod, :protected, options) } if yaml[:protected].is_a?(Hash)
			yaml[:public].each { |k, v| Settings.set(k, v, mod, :public, options) } if yaml[:public].is_a?(Hash)
			return yaml[:dependencies] || []
		end

		# Returns an array with all modules. If the modules aren't loaded yet, it will do so and check the dependecies
		def modules
			if @modules.nil?
				@modules = []
				API.log.info('Loading the API core')
				mod_dependencies = {core: load_module(:core)}
				paths = ["#{Mojura::PATH}/api/resources/"]
				paths.push('./api/resources/') if Dir.exist?('./api/resources/')

				paths.each { | path |
					Dir.foreach(path) { | name |
						if (name[0] != '.') && (File.directory?("#{path}#{name}"))
							mod = name.to_sym
							API.log.info("Loading module #{mod}")
							@modules.push(mod)
							mod_dependencies[mod] = load_module(mod)
						end
					}
				}
				mod_dependencies.each { |mod, dependencies|
					unless dependencies.empty?
						API.log.info("Checking dependencies for module #{mod}:")
						dependencies.each { |needed_mod, needed_version|
							real_version = Settings.get_s(:version, needed_mod)
							API.log.info("   #{needed_mod} #{needed_version}: found #{real_version}")
							raise DependencyException.new(mod, needed_mod) if real_version.empty?
							if real_version.to_s < needed_version.to_s
								raise DependencyVersionException.new(mod, needed_mod, needed_version, real_version)
							end
						}
					end
				}
			end
			return @modules
		end

		# Loads all the REST resources, which are stored in the modules folder.
		# Each resource should be descendant of the RestResource object and deals with
		# the GET, PUT, POST and DELETE requests for that specific resource.
		def load_resources(path)
			mods = modules
			mods.each { | mod |
				if File.exists?("#{path}/#{mod}/#{mod}.rest.rb")
					require "#{path}/#{mod}/#{mod}.rest.rb"
				end
			}
		end

		# Registers a resource, specifid with the specified module and item(s)_paths
		def register_resource(object)
			API.log.info("Registering resource #{object.module.to_s}/#{object.items_path}")
			items_path = "#{object.module.to_s}/#{object.items_path}".gsub(/(\/*)$/, '')
			item_path = "#{object.module.to_s}/#{object.item_path}".gsub(/(\/*)$/, '')
			if object.items_path == object.item_path
				raise Exception.new('Resource registration conflict: the items_path and item_path shouldn\'t be equal.')
			else
				@resources[items_path] = {type: :items, object: object} unless object.items_path.nil?
				@resources[item_path] = {type: :item, object: object} unless object.item_path.nil?
			end
		end

		# Executes a complete request. Request could be a resource, help or nothing
		def call(request_path, params = {}, method = 'get')
			Thread.current[:mojura][:current_call] = request_path
			self.load if (!@loaded)
			API.log.debug("calling '#{request_path}' with params #{params}")

			params ||= {}
			params.symbolize_keys!
			if request_path == ''
				result = []
				mods = modules
				mods.each { |mod|
					result << {module: mod, url: self.api_url + mod.to_s}
				}
			elsif request_path == 'help'
				result = help(params)
			elsif request_path == 'setup'
				result = setup(method, params)
			elsif request_path == 'salt'
				result = salt(params)
			elsif request_path == 'authenticate'
				result = authenticate(params)
			elsif request_path == 'signoff'
				result = sign_off(params)
			elsif request_path == 'maintenance'
				raise NoRightsException.new unless current_user.administrator?
				result = maintenance(params)
			else
				result = call_resource(request_path, params, method)
			end

			if (params[:show_env] == 'true') && (Settings.get_s(:developing))
				result = {result: result} unless result.is_a?(Hash)
				result[:env] = Thread.current[:mojura]
			end

			unless params[:include_settings].to_s.empty?
				result = {result: result} unless result.is_a?(Hash)
				result[:settings] ||= {}
				params[:include_settings].split(',').each { | s |
					mod, key = s.split('.', 2)
					scopes = API.current_user.administrator? ? [:private, :protected, :public] : [:public]
					result[:settings][mod] ||= {}
					result[:settings][mod][key] = Settings.get_raw(key, mod, scopes)
				}
			end

			Thread.current[:mojura][:current_call] = nil
			return result
		end

		# Executes the specified method on a specific resource
		def call_resource(request_path, params = {}, method = 'get')
			result = []
			resource = nil
			return_help = request_path.match(/\/help$/)
			request_path = request_path[0..-6] if return_help

			@resources.each { |p, obj|
				p = p.gsub(/^\//, '').gsub(/\//, "\\/").gsub(/\[(\w+)\]/) { |match|
					'(' + obj[:object].uri_id_to_regexp(match[1..-2]) + ')'
				}
				request_path.match(/^#{p}$/) { |m|
					resource = obj
					data = m.to_a
					params[:query_string] = data.shift
					params[:ids] = data
				}
			}

			if resource.nil?
				raise UnknownModuleException.new(request_path)
			elsif return_help
				result = resource[:object].conditions
			elsif (resource[:type] == :items) && (method == 'get')
				result = resource[:object].all(params) if resource[:object].required_params_present?(:all, params)
			elsif (resource[:type] == :items) && (method == 'post')
				result = resource[:object].post(params) if resource[:object].required_params_present?(:post, params)
			elsif (resource[:type] == :item) && (method == 'get')
				result = resource[:object].get(params) if resource[:object].required_params_present?(:get, params)
			elsif (resource[:type] == :item) && (method == 'put')
				result = resource[:object].put(params) if resource[:object].required_params_present?(:put, params)
			elsif method == 'delete' # Delete is supported both by a list of resource and a single resource item
				result = resource[:object].delete(params) if resource[:object].required_params_present?(:delete, params)
			else
				raise UnknownModuleException.new(request_path)
			end
			raise InvalidResourceResultException.new if (!result.is_a?(Array) && !result.is_a?(Hash))
			return result
		end

		# API method /help. Returns all documentation of the API.
		# noinspection RubyUnusedLocalVariable
		def help(params)
			result = {core: {title: 'Core', resources: [core_conditions]}}
			@resources.each { |_, v|
				if v[:type] == :items
					conditions = v[:object].conditions
					unless conditions.empty?
						result[(v[:object].module)] = {title: v[:object].module_name, resources: []} if (result[(v[:object].module)].nil?)
						result[(v[:object].module)][:resources].push(conditions)
					end
				end
			}
			result.each { |_, mod_info|
				mod_info[:resources].sort! { |a, b| a[:resourceid] <=> b[:resourceid] }
			}
			return result
		end

		# API method /setup. Creates an admin account, and a page if there are no users.
		#noinspection RubyUnusedLocalVariable
		def setup(method, params)
			users = Users.new({'$or' => [{is_admin: true}]}, {ignore_rights: true})
			pages = Pages.new()
			if (method == 'post')
				users = Users.new({'$or' => [{is_admin: true}]}, {ignore_rights: true})
				result = ''
				if users.count == 0
					user = User.new()
					realm = Settings.get_s(:realm)
					username = params[:username] || 'admin'
					digest = params[:digest] || Digest::MD5.hexdigest("#{username}:#{realm}:admin").to_s
					user.username = username
					user.firstname = 'Administrator'
					user.lastname = 'Administrator'
					user.email = 'admin@127.0.0.1'
					user.password = digest
					user.is_admin = true
					user.state = :active
					user.save_to_db
					result = "Created an admin account with username #{username}. "
				end
				if pages.count == 0
					page = Page.new
					page.title = params[:title] || 'Home'
					page.save_to_db
					result += "Created a empty page with title #{page.title}."
				end
				result = "Didn't do anything: an admin account and a default already existed." if result.empty?
				return [result]
			else
				return { realm: Settings.get_s(:realm), needs_admin: (users.count == 0), needs_page: (pages.count == 0)	}
			end
		end

		# API method /salt. Returns a salt which is needed for authentication
		# :category: Core API methods
		# noinspection RubyUnusedLocalVariable
		def salt(params)
			session[:salt] = ::SecureRandom.hex(16) if !session.include?(:salt)
			return {salt: session[:salt], realm: Settings.get_s(:realm)}
		end

		# API method /authenticate. Authenticates a user and returns the user as object if successful.
		# If the credentials are incorrect, an error will be raised.
		# :category: Core API methods
		def authenticate(params)
			API.salt(params) # forces a generated salt
			users = Users.new({username: params[:username]}, :ignore_rights => true)
			raise InvalidAuthentication.new if (users.count != 1)
			user = users.first
			iterations = 500 + (user.username + Settings.get_s(:realm)).length
			crypted = OpenSSL::PKCS5.pbkdf2_hmac_sha1(user.digest, API.session[:salt], iterations, 64).unpack('H*')[0]
			if params[:password] == crypted
				API.session[:uid] = user.id
				user.generate_new_cookie_token if (params[:set_cookie] == 'true')
				API.log.info("Authentication for #{:username} succeeded")
				return user.to_h
			else
				API.session[:uid] = nil
				API.log.warn("Authentication for #{:username} failed")
				API.log.debug("Digest: #{user.digest}\nSent password: #{params[:password]}\nStored password: #{crypted}")
				raise InvalidAuthentication.new
			end
		end

		# API method /sign_off. Signs out the current user.
		# :category: Core API methods
		# noinspection RubyUnusedLocalVariable
		def sign_off(params)
			API.session.clear
			return {success: 'true'}
		end

		# API method /reset_password. Creates a new password and sends it to the owner
		# :category: Core API methods
		def reset_password
			users = Users.new({username: params[:username]}, :ignore_rights => true)
			raise DataNotFoundException.new(:username, params[:username]) if (users.count != 1)
			user = users.first
			return user.reset_password
		end

		# API information of the core.
		def core_conditions
			{
				name: 'Core',
				resourceid: 'core',
				description: 'The Mojura API is mainly <a href=\'http://en.wikipedia.org/wiki/Representational_state_transfer\'>REST</a>-based. The following functions, however, are not RESTful. They are needed for authentication.',
				methods: {
					authenticate: {
						uri: API.api_url + 'authenticate',
						description: 'Authenticates a user. To encrypt the password, the client-side needs the following steps:<ol><li>Request a salt (see Salt). It will also return a realm.</li><li>Make a digest using MD5([username]:[realm]:[password]).</li><li>Encrypted the digest with PBKDF2 using the given salt and a number of iterations. This number is the calculation of 500 + the length of the username + the length of the realm. PBKDF2 should be using SHA256 as hasher.</li></ol>',
						attributes: {
							username: {required: true, type: String, description: 'The username'},
							password: {required: true, type: String, description: 'The encrypted digest'},
						}
					},
					salt: {
						uri: API.api_url + 'salt',
						description: 'Returns the salt and the realm, which are needed on the client-side to. Also check the authenticate function.',
					},
					setup: {
						uri: API.api_url + 'setup',
						description: "Creates a default administrator account and default home page if there aren't any in the system.",
					},
					signoff: {
						uri: API.api_url + 'signoff',
						description: 'Signs off the current authenticated user. After a signoff, a fresh salt should be generated.',
					}
				}
			}
		end

		def maintenance(params)
			result = {}
			@modules.each { | mod |
				Settings.get_h(:maintenance, mod).each { | method, collections |
					collections.each { | collection, klass |
						result[mod] ||= {}
						result[mod][method] ||= {}
						if (method == :reindex_search)
							result[mod][method][collection] = reindex_search(collection, klass)
						elsif (method == :right_2_rights)
							result[mod][method][collection] = right_2_rights(collection)
						end
					}
				}
			}
			return result
		end

		def reindex_search(collection_name, klass)
			collection = MongoDb.collection(collection_name)
			count = 0
			collection.find.each { | row |
				object = MojuraAPI.const_get(klass).new
				object.load_from_hash(row, true)
				object.save_to_search_index
				count += 1
			}
			return count
		end

		def right_2_rights(collection_name)
			collection = MongoDb.collection(collection_name)
			collection.update({}, {'$rename' => {'right' => 'rights'}}, multi: true)
		end

		private :load_module

	end

end