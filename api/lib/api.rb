# This file contains the Mojura API module.
# Author:: Taco Jan Osinga, Osinga Software
# Website:: www.mojura.nl

require 'fileutils'
require 'pbkdf2'
require 'digest/md5'
require 'yaml'
require 'log4r'
require 'securerandom'
require 'api/lib/mongodb'
require 'api/lib/exceptions'
require 'api/lib/ubbparser_additions'
require 'api/lib/settings'
require 'api/resources/locale/locale.object'
require 'api/resources/users/users.objects'

module MojuraAPI

	# The API module is the core of all data handling of Mojura. All data logic is and should be
	# implemented in this API and never in the WebApp. The WebApp should be considered as one
	# of the possible clients.
	module API

		# Convert this module to a singleton
		extend self

		# Module instances used for internal use. Some variables are accesible via identical named methods
		@settings = {}
		@modules = nil
		@resources = {}
		@loaded = false
		@log = nil

		# Loads all settings, resources and makes the connection with the database
		def load
			return if (@loaded)
			@log = Log4r::Logger.new('API')
			@log.add(Log4r::Outputter.stdout)
			@log.info('----- Loading the API -----')
			MongoDb.connect(Settings.get_s(:database))
			self.load_resources
			@log.info('----- The API is loaded -----')

			@loaded = true
		end

		# Initialize the current thread with thread-specific information, mainly form the request data.
		# Each thread equalizes one request. Thread handling is done soly by this API module.
		def init_thread(env = {})
			self.load
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
		end

		# Returns the current user.
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
			yaml = YAML.load_file(filename) rescue {}
			yaml.symbolize_keys!
			options = {ignore_if_exists: true, type: :file}
			Settings.set(:version, (yaml[:version] || '0.0.0'), mod, :protected, options)
			Settings.set(:global_rights, yaml[:global_rights], mod, :protected, options) if yaml[:global_rights].is_a?(Array)
			Settings.set(:object_rights, yaml[:object_rights], mod, :protected, options) if yaml[:object_rights].is_a?(Hash)
			yaml[:private].each { |k, v| Settings.set(k, v, mod, :private, options) } if yaml[:private].is_a?(Hash)
			yaml[:protected].each { |k, v| Settings.set(k, v, mod, :protected, options) } if yaml[:protected].is_a?(Hash)
			yaml[:public].each { |k, v| Settings.set(k, v, mod, :public, options) } if yaml[:public].is_a?(Hash)
			return yaml[:dependencies] || []
		end

		# Returns an array with all modules. If the modules aren't loaded yet, it will do so and check the dependecies
		def modules
			if @modules.nil?
				@modules = []
				API.log.info("Loading the API core")
				mod_dependencies = {:core => load_module(:core)}
				Dir.foreach('api/resources/') { |name|
					if (name[0] != '.') && (File.directory?('./api/resources/' + name))
						mod = name.to_sym
						API.log.info("Loading module #{mod}")
						@modules.push(mod)
						mod_dependencies[mod] = load_module(mod)
					end
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
		def load_resources
			mods = modules
			mods.each { | mod |
				if File.exists?("api/resources/#{mod}/#{mod}.rest.rb")
					require "api/resources/#{mod}/#{mod}.rest.rb"
				end
			}
		end

		# Registers a resource, specifid with the specified module and item(s)_paths
		def register_resource(object)
			API.log.info("Registering resource #{object.module.to_s}/#{object.items_path}")
			items_path = "#{object.module.to_s}/#{object.items_path}".gsub(/(\/*)$/, '')
			item_path = "#{object.module.to_s}/#{object.item_path}".gsub(/(\/*)$/, '')
			@resources[items_path] = {type: :items, object: object}
			@resources[item_path] = {type: :item, object: object} if (items_path != item_path)
		end

		# Executes a complete request. Request could be a resource, help or nothing
		def call(request_path, params = {}, method = 'get')
			self.load if (!@loaded)
			API.log.debug("calling '#{request_path}' with params #{params}")

			params ||= {}
			params.symbolize_keys!
			if (params[:show_env] == 'true') && (Settings.get_s(:developing))
				result = Thread.current[:mojura]
			elsif request_path == ''
				result = []
				mods = modules
				mods.each { |mod|
					result << {module: mod, url: self.api_url + mod.to_s}
				}
			elsif request_path == 'help'
				result = help(params)
			elsif request_path == 'setup'
				result = setup(params)
			elsif request_path == 'salt'
				result = salt(params)
			elsif request_path == 'authenticate'
				result = authenticate(params)
			elsif request_path == 'signoff'
				result = sign_off(params)
			else
				result = call_resource(request_path, params, method)
			end
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
			elsif (resource[:type] == :items) && (method == 'put')
				result = resource[:object].put(params) if resource[:object].required_params_present?(:put, params)
			elsif (resource[:type] == :item) && (method == 'get')
				result = resource[:object].get(params) if resource[:object].required_params_present?(:get, params)
			elsif (resource[:type] == :item) && (method == 'post')
				result = resource[:object].post(params) if resource[:object].required_params_present?(:post, params)
			elsif method == 'delete'
				# No idea why RubyMine sees result as unused
				#noinspection RubyUnusedLocalVariable
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
			load_resources
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

		# API method /setup. Creates an admin account if there are no users.
		def setup(params)
			users = Users.new({'$or' => [{is_admin: true}, {username: 'admin'}]}, {ignore_rights: true})
			if users.count == 0
				user = User.new()
				realm = Settings.get_s(:realm)
				user.username = 'admin'
				user.firstname = 'Administrator'
				user.lastname = 'Administrator'
				user.email = 'admin@127.0.0.1'
				user.password = Digest::MD5.hexdigest("admin:#{realm}:admin").to_s
				user.is_admin = true
				user.state = :active
				user.save_to_db
				return ['Created an administrator with the default credentials']
			else
				return ['An administrator or user admin already exists']
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
			crypted = PBKDF2.new(:password => user.digest, :salt => API.session[:salt], :iterations => iterations, :key_length => 64, :hash_function => 'SHA1').hex_string
			if params[:password] == crypted
				API.session[:uid] = user.id
				user.generate_new_cookie_token if (params[:set_cookie] == 'true')
				API.log.info("Authentication for #{:username} succeeded")
				return user.to_a
			else
				API.session[:uid] = nil
				API.log.warn("Authentication for #{:username} failed")
				API.log.debug("Digest: #{usder.digest}\nSent password: #{params[:password]}\nStored password: #{crypted}")
				raise InvalidAuthentication.new
			end
		end

		# API method /sign_off. Signs out the current user.
		# :category: Core API methods
		# noinspection RubyUnusedLocalVariable
		def sign_off(params)
			API.session[:uid] = nil
			API.current_user.clear_all_cookie_tokens
			API.session[:salt] = SecureRandom.hex(16)
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
					signoff: {
						uri: API.api_url + 'signoff',
						description: 'Signs off the current authenticated user. After a signoff, a fresh salt should be generated.',
					}
				}
			}
		end

		private :load_module

	end

end