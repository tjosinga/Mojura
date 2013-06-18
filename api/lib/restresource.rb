require 'api/lib/datatypes'
require 'api/lib/filterparser'

module MojuraAPI

	# Base class for all REST resources.
	# REST resources are responsible for checking the requirements.
	# Other validations are checked by the objects itself.
	class RestResource

		attr_reader :module, :items_path, :item_path

		# Initializes the REST resouce
		def initialize(mod, items_path, item_path)
			@module = mod
			@items_path = items_path
			@item_path = item_path
		end

		def module_name
			return @module.capitalize
		end

		def name
			return @module.capitalize
		end

		#noinspection RubyDeadCode
		def description
			raise NotImplementedException.new
		end

		#noinspection RubyUnusedLocalVariable,RubyUnusedLocalVariable
		def uri_id_to_regexp(id_name)
			'[0-9a-f]{24}|0|new'
		end

		# Returns a set of objects
		#noinspection RubyUnusedLocalVariable
		def all(params)
			raise UnsupportedMethodException(:all)
		end

		# Returns the url of another page of the requested resource
		def new_page_url(new_page, params)
			result = API.api_url + params[:query_string] + '?'
			params[:page] = new_page
			newparams = []
			params.each { |k, v| newparams << "#{k}=#{v}" if ((k != :query_string) && (k != :ids)) }
			result += newparams.join('&')
			return result
		end

		# Parses the page information from the request, and includes page information to the response.
		def paginate(params)
			options = {}
			options[:page] = params[:page].to_i if (!params[:page].nil? && (params[:page].is_a?(Integer) || params[:page].numeric?))
			options[:pagesize] = params[:pagesize].to_i if (!params[:pagesize].nil? && (params[:pagesize].is_a?(Integer) || params[:pagesize].numeric?))
			options[:sort] = JSON.parse(params[:sort]) rescue nil
			objects = yield options
			result = {}
			result[:count] = objects.count
			result[:items] = objects.to_a
			pagecount = (objects.count / (objects.pagesize * 1.0)).ceil
			result[:pageinfo] = {
				current: objects.page,
				pagesize: objects.pagesize,
				pagecount: pagecount
			}
			result[:pageinfo][:previous] = new_page_url(objects.page - 1, params) if objects.page > 1
			result[:pageinfo][:next] = new_page_url(objects.page + 1, params) if objects.page < pagecount
			return result
		end

		def filter(params)
			FilterParser.parse(params[:filter])
		end

		# Creates a new object
		#noinspection RubyUnusedLocalVariable
		def put(params)
			raise UnsupportedMethodException(:put)
		end

		# Returns an object
		#noinspection RubyUnusedLocalVariable
		def get(params)
			raise UnsupportedMethodException(:get)
		end

		# Updates an object
		#noinspection RubyUnusedLocalVariable
		def post(params)
			raise UnsupportedMethodException(:post)
		end

		# Removes an object
		#noinspection RubyUnusedLocalVariable
		def delete(params)
			raise UnsupportedMethodException(:delete)
		end

		#------------------------------------------------------------------------------------------------------------------

		# Checkes wether all required parameters are present in the request
		def required_params_present?(method, params)
			conds = case method
				        when :all then
					        self.all_conditions
				        when :put then
					        self.put_conditions
				        when :get then
					        self.get_conditions
				        when :post then
					        self.post_conditions
				        when :delete then
					        self.delete_conditions
				        else
			        end

			if !conds.nil? && !conds[:attributes].nil?
				missing = []
				conds[:attributes].each { |k, v|
					params[k] = StringConvertor.convert(params[k], v[:type]) if (!params[k].nil?)
					missing << k if (!v.nil? && v[:required] && (params[k].nil? || params[k] == ''))
				}
				raise MissingParamsException.new(missing) if !missing.empty?
			end

			return true
		end

		#------------------------------------------------------------------------------------------------------------------

		#noinspection RubyUnusedLocalVariable
		def check_rights(type, object = nil, group_right = '')
			raise NotOverridenException.new
		end

		#------------------------------------------------------------------------------------------------------------------

		# Return all conditions
		def conditions
			result = {
				name: self.name,
				resourceid: (self.module + '_' + self.items_path.gsub(/\//, '_')).gsub(/_$/, '').gsub(/[\[|\]]/, ''),
				description: self.description,
				methods: {
					all: self.all_conditions,
					get: self.get_conditions,
					put: self.put_conditions,
					post: self.post_conditions,
					delete: self.delete_conditions
				}
			}
			result[:methods].delete(:all) if result[:methods][:all].nil?
			result[:methods].delete(:get) if result[:methods][:get].nil?
			result[:methods].delete(:put) if result[:methods][:put].nil?
			result[:methods].delete(:post) if result[:methods][:post].nil?
			result[:methods].delete(:delete) if result[:methods][:delete].nil?

			result[:methods].each { |k, v|
				if !v.include?(:uri)
					if k == :all || k == :put
						v[:uri] = API.api_url + "#{@module}/#{@items_path}"
					else
						v[:uri] = API.api_url + "#{@module}/#{@item_path}"
					end
				end
			}

			return result
		end

		# Returns a description of this resource
		def description
			nil
		end

		# Returns the conditions of the 'all' method
		def all_conditions
			nil
		end

		# Returns the conditions of the 'put' method
		def put_conditions
			nil
		end

		# Returns the conditions of the 'get' method
		def get_conditions
			nil
		end

		# Returns the conditions of the 'post' method
		def post_conditions
			nil
		end

		# Returns the conditions of the 'delete' method
		def delete_conditions
			nil
		end

		# Returns conditions for pagination, mostly used in the :all method of resources
		def page_conditions
			{
				page: {required: false, type: Integer, description: 'Number of the page of the items. The first page is page 1, second page is page 2. Default is 1.'},
				pagesize: {required: false, type: Integer, description: 'The amount of items per page.'}
			}
		end

		# Returns conditions for pagination, mostly used in the :all method of resources
		def filter_conditions
			{
				filter: {required: false, type: String, description: 'A string containing the filter. See xxxx for more information.'},
			}
		end

		# Returns conditions for tags, mostly used in the :put method of resource
		def tags_conditions
			{
				tags: {required: false, type: Array, description: 'An array of tags for this resource'},
			}
		end

		# Returns conditions for rights, mostly used in the :put method of resource
		def rights_conditions
			{
				userid: {required: false, type: Array, description: 'A list of user ids who owning this item.'},
				groupip: {required: false, type: Array, description: 'A list of group ids who owning this item.'},
				right: {required: false, type: Integer, description: 'The CRUD code which tells what the specific rights for the user and group members on this item is.'}
			}
		end

	end

end