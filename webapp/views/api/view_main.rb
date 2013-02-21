module MojuraWebApp

	class APIView < BaseView

		attr_reader :modules

		def initialize(options = {})
			super
			STDOUT << "initializing APIView\n"
			self.load_api_help
			WebApp.page.include_script('APIGotoHash(location.hash);')
		end

		def load_api_help
			api_modules = WebApp.api_call('help')
			method_names = {all: {http: 'GET', title: 'Multiple items'},
                      get: {http: 'GET', title: 'Single item'},
                      put: {http: 'PUT', title: 'Add item'},
                      post: {http: 'POST', title: 'Edit item'},
                      delete: {http: 'DELETE', title: 'Delete item'}}
			@modules = []
 			api_modules.each { | mod, mod_data |
 				resources = []
 				mod_data[:resources].each { | resource |
 					methods = []
 					resource[:methods].each { | method_name, method_info |
 						attributes = []
 						if method_info.include?(:attributes)
	 						method_info[:attributes].each { | field_name, field_info |

	 							attributes.push({name: field_name,
                                  type: field_info[:type],
                                  required: field_info[:required],
                                  description: field_info[:description]})
	 						}
	 					end
	 					http, title, description = 'GET', method_name.capitalize, method_info[:description]
	 					http = method_names[method_name][:http] if method_names.include?(method_name)
	 					title = method_names[method_name][:title] if method_names.include?(method_name)
	 					description = description.gsub(/\n1./, '<ol><li>').gsub(/\n[0-9]./, '</li><li>') + '</li></ol>' if (method_name == :authenticate)
 						methods.push({name: method_name,
                           description: description.gsub(/\n/, '<br />'),
                           uri: method_info[:uri],
                           http: http,
                           title: title,
                           has_attributes: (attributes.count > 0),
                           attributes: attributes})
 					}
 					resources.push({name: resource[:name], description: resource[:description], resourceid: resource[:resourceid], methods: methods})
 				}
 				@modules.push({module: mod, title: mod_data[:title], resources: resources})
 			}
 			@modules.sort!{ | a, b |
				if a[:title] == 'Core'
					-1
				elsif b[:title] == 'Core'
					1
				else
					a[:title] <=> b[:title]
	 			end
 			}
		end

		def is_active
			if @is_active.nil?
				@is_active = false
				return true
			else
				return false
			end
		end

		def set_active
			@is_active = nil
			return nil
		end

		def is_sub_active
			if @is_sub_active.nil?
				@is_sub_active = false
				true
			else
				false
			end
		end

		def set_sub_active
			@is_sub_active = nil
			return nil
		end

	end

	WebApp.register_view('api', APIView)

end