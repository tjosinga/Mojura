require 'mongo'
require 'json'
require 'api/lib/richtext'
require 'api/lib/validator'
require 'api/lib/stringconvertor'
require 'api/lib/mongodb'
require 'api/lib/dbobject_rights'
require 'api/lib/dbobject_tags'
require 'api/lib/dbobject_votes'
require 'api/lib/dbobject_orderid'
require 'api/lib/dbobject_searchable'

module MojuraAPI

	# DbObject is a base class for all database driven objects. It has support for saving and loading to a database,
	# caching and validation when setting variables.
	# :category: DbObject

	class DbObject

		include DbObjectSearchable

		@module = nil
		@collection = nil
		@loaded = false
		@options = nil

		attr_reader :id, :id_type, :loaded, :fields, :module

		# Initializes the API. It calls the get_fields of its
		def initialize(db_col_name, id = nil, options = {})
			raise Exception.new 'DbObject may only be inherited' if (self.instance_of?(DbObject))
			id = nil if %w(0 new root empty nil null).include?(id)
			@loaded = false
			@options = options || {}
			@id = id
			@id_type = (@options[:id_type] == :binary) ? :binary : :objectid
			@collection = MongoDb.collection(db_col_name)
			@module = (@options.has_key?(:module_name)) ? @options[:module_name] : db_col_name
			@options[:api_url] ||= API.api_url + @module
			@fields = get_fields(:load_fields)

			# include all fields of added mixins, if it has a method named load_xxxx_fields
			self.class.included_modules.each { | mod |
				mod.instance_methods.each { | method |
					@fields.merge!(get_fields(method)) if (method.match(/^load_\w+_fields$/))
				}
			}

			@fields.each { |_, v|
				v[:value] = v[:default]
				v.delete(:default)
				v[:changed] = false
			}
			self.load_from_db if (!id.nil?)
		end

		def load_fields
			raise 'Should be overloaded'
		end

		def get_fields(proc_name)
			return nil if (proc_name.nil?)
			result = {}
			send(proc_name) { |name, type, options|
				options ||= {}
				result[name] = {
					type: type,
					required: (options[:required]),
					validations: options[:validations],
					hidden: (options[:hidden]),
					default: options[:default],
					group: options[:group],
					searchable: options[:searchable].is_a?(TrueClass),
					searchable_weight: options[:searchable_weight] || 1,
					extended_only: (options[:extended_only]),
				}
				if type == RichText
					result[(name.to_s + '_markup').to_sym] = {
						type: String, required: false, validations: nil, hidden: true, default: 'ubb', group: nil, extended_only: true
					}
				end
			}
			return result
		end

		def set_field_value(key, value, validate_value = true, set_changed_flag = true)
			key = key.to_sym
			return if @fields[key].nil?
			if (key == :rights) && (!value.is_a?(Hash))
				value = DbObjectRights.int_to_rights_hash(value.to_i)
			else
				value = StringConvertor.convert(value, @fields[key][:type])
			end
			if (@fields[key][:value] != value) && ((!validate_value) || (self.validate_field_value(key, value)))
				@fields[key][:orig_value] = @fields[key][:value] unless @fields[key][:changed]
				@fields[key][:changed] = true if (set_changed_flag)
				@fields[key][:value] = value
			end
		end

		# Returns the value of a specific field
		def get_field_value(key)
			return nil if @fields[key.to_sym].nil?
			return @fields[key.to_sym][:value]
		end

		# getter and setter for object fields. Database which
		def method_missing(name, *arguments)
			value = arguments[0]
			if name.to_s[-1, 1] == '='
				key = name.to_s[0..-2].to_sym
				self.set_field_value(key, value)
			else
				if @fields.include?(name.to_sym)
					return self.get_field_value(name)
				else
					super
				end
			end
		end

		# Returns true if the object responds to the given method_sym.
		def respond_to?(method_sym, include_private = false)
			return @fields.include?(method_sym) || super
		end

		# Converts the values hash to a string
		# :category: Conversion methods
		def to_s
			return self.to_a.to_s
		end

		def api_url
			@options[:api_url] + '/' + @id
		end

		# Extracts all values of the database object fields and returns them in a hash
		# :category: Conversion methods
		def to_a(compact = false)
			result = {}
			result[:id] = self.id
			@fields.each { |field, options|
				if !options[:hidden] && (!options[:extended_only] || !compact)
					value = Marshal.load(Marshal.dump(options[:value]))
					begin
						value = yield field, value, compact
					rescue
						# Do nothing
					end
					if options[:type] == RichText
						markup = @fields[(field.to_s + '_markup').to_sym][:value] rescue ''
						value = RichText.new(value, markup).to_parsed_a(compact)
					elsif options[:type] == DateTime
						value = Date.parse(value) if value.is_a?(String)
						value = value.localtime.strftime('%FT%T') if !value.nil?
					elsif options[:type] == Date
						value = Time.parse(value) if value.is_a?(String)
						value = value.localtime.strftime('%F') if !value.nil?
					elsif options[:type] == Time
						value = Time.parse(value) if value.is_a?(String)
						value = value.localtime.strftime('%T') if !value.nil?
					elsif options[:type] == BSON::ObjectId
						value = value.to_s if !value.nil?
					elsif options[:type] == BSON::Binary
						value = value.unpack('H*')[0] if !value.nil?
					end
					if !options[:group].nil?
						group = options[:group]
						result[group] = {} if (result[group].nil?)
						result[group][field] = value
					else
						result[field] = value
					end
				end
			}
			if ((result.has_key?(:rights)) && (self.class.include?(DbObjectRights)))
				result[:rights][:allowed] = rights_as_bool
				result[:rights][:rights] = DbObjectRights.rights_hash_to_int(result[:rights][:rights])
			end
			result[:api_url] = api_url if (compact)
			return result
		end

		# Returns the all information on the fields on their values
		# :category: Conversion methods
		def to_debug_a
			return @fields
		end

		# Validates the value for a specific field
		# :category: Validation methods
		def validate_field_value(key, value)
			result = {}
			options = @fields[key.to_sym]
			validations = (options[:validations] || {})
			validations[:is_required] = true if options[:required]
			validations.each { |validation, params|
				method_object = Validator.method((validation.to_s + '?').to_sym)
				cnt = method_object.parameters.count
				is_valid = true
				if cnt == 1
					is_valid = method_object.call(value)
				elsif cnt == 2
					is_valid = method_object.call(value, params)
				end
				if !is_valid
					result[validation.to_s] ||= {}
					result[validation.to_s] = key
				end
			}
			raise ValidationError.new(result.keys.join(', '), key, value) if !result.empty?
			return true
		end

		# Validates all values of all fields.
		# :category: Validation methods
		def validate
			result = {}
			@fields.each { |field, options| self.validate_field_value(field, options[:value]) }
			result = true if (result.empty?)
			return result
		end

		# Loads all values from an hash and validates them.
		# :category: Database methods
		def load_from_hash(values, silent = false)
			values.each { | k, v |
				k = k.to_sym
				k = :rights if (silent && k == :right) # TODO: Remove later. Now here because I changed right to rights.
				v.symbolize_keys! if (v.is_a?(Hash) || v.is_a?(Array))
				if @fields.has_key?(k)
					(silent) ? @fields[k][:value] = v : self.set_field_value(k, v)
				elsif (k == :id) || (k == :_id)
					@id = (v.is_a?(BSON::Binary)) ? v.unpack('H*')[0] : v.to_s
				end
			}
			self.loaded = true
			return self
		end

		# Retrieves the object data from the database and loads it in this object using load_from_hash.
		# sets values directly to avoid validation and :changed being set
		# :category: Database methods
		def load_from_db
			id = (@id_type == :binary) ? BSON::Binary.new([@id].pack('H*')) : BSON::ObjectId(@id)
			data = @collection.find_one('_id' => id).to_h
			return self.load_from_hash(data, true)
		end

		# Saves all object data to the database.
		# :category: Database methods
		def save_to_db
			data = {}
			@fields.each { |key, options|
				data[key] = options[:value].dup rescue options[:value] if (@id.nil? || options[:changed])
			}
			self.on_save_data(data)
			return self if (data.empty?)

			data.stringify_keys!
			if @id.nil?
				bin_id = @collection.insert(data)
				@id = (bin_id.is_a?(BSON::ObjectId)) ? bin_id.to_s : bin_id.unpack('H*')[0]
			else
				id = (@id_type == :binary) ? BSON::Binary.new([@id].pack('H*')) : BSON::ObjectId(@id)
				@collection.update({_id: id}, {'$set' => data}, {upsert: true}) if (!data.empty?)
			end
			save_to_search_index if regenerate_for_search_index?

			@fields.each { |_, options| options[:changed] = false }
			@options[:tree].new.refresh if @options.has_key?(:tree)
			return self
		end

		def save_to_search_index
			rights = {
				rights: (self.rights rescue 0),
				userids: (self.userids rescue []),
				groupids: (self.groupids rescue [])
			}
			if (rights[:rights].nil?)
				rights[:rights] = Settings.get_h(:object_rights, @module)[self.class.name[11..-1].to_sym] || 0x704
			end
			rights[:rights] = DbObjectRights.int_to_rights_hash(rights[:rights].to_i) unless rights[:rights].is_a?(Hash)
			title, description = self.get_search_index_title_and_description
			SearchIndex.set(@id, @collection.name, title, description, api_url, get_weighted_keywords, rights)
		end

		# Sets all the values to the original state
		def revert
			@fields.each { | _, options|
				if options[:changed]
					options[:value] = options[:orig_value]
					options[:changed] = false
				end
			}
		end

		# A dummy method which could be used to alter the data that is stored in the database.
		#noinspection RubyUnusedLocalVariable
		def on_save_data(data)
		end

		# Deletes the object from the database.
		# :category: Database methods
		def delete_from_db
			SearchIndex.unset(@id)
			id = (@id_type == :binary) ? BSON::Binary.new([@id].pack('H*')) : BSON::ObjectId(@id)
			@collection.remove({_id: id})
			@id = nil
			@options[:tree].new.refresh if @options.has_key?(:tree)
			return self
		end

		# Returns true if any of the values is changed since the last load from the database.
		# :category: Database methods
		def changed?
			@fields.each do |_, options|
				if options[:changed]
					return true
				end
			end
			return false
		end

	end

end