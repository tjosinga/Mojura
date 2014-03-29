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

module MojuraAPI

	# DbObject is a base vlass for all database driven objects. It has support for saving and loading to a database,
	# caching and validation when setting variables.
	# :category: DbObject
	class DbObject

		@object_module = nil
		@object_collection = nil
		@loaded = false
		@options = nil

		attr_reader :id, :loaded, :fields, :module

		# Initializes the API. It calls the get_fields of its
		def initialize(db_col_name, id = nil, options = {})
			raise Exception.new 'DbObject may only be inherited' if (self.instance_of?(DbObject))
			id = nil if %w(0 new root empty nil null).include?(id)
			@loaded = false
			@options = options || {}
			@id = id
			@object_collection = MongoDb.collection(db_col_name)
			@object_module = (@options.has_key?(:module_name)) ? @options[:module_name] : db_col_name
			@options[:api_url] ||= API.api_url + @object_module
			@fields = get_fields(:load_fields)

			# include all fields of added mixins, if it has a method named load_xxxx_fields
			self.class.included_modules.each { |mod|
				mod.instance_methods.each { |method|
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
			value = StringConvertor.convert(value, @fields[key][:type])
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
			name = name.to_s
			if name[-1, 1] == '='
				key = name[0..-2]
				self.set_field_value(key, value)
			else
				return self.get_field_value(name)
			end
		end

		# Converts the values hash to a string
		# :category: Conversion methods
		def to_s
			return self.to_a.to_s
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
					elsif options[:type] == Time
						value = value.localtime.iso8601 if !value.nil?
					elsif options[:type] == BSON::ObjectId
						value = value.to_s if !value.nil?
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
				result[:rights][:right] = DbObjectRights.rights_hash_to_int(result[:rights][:right])
			end
			result[:api_url] = @options[:api_url] + '/' + @id if (compact)
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
			values.each { |k, v|
				if @fields.has_key?(k.to_sym)
					if (k.to_sym == :right) && (!v.is_a?(Hash))
						self.set_field_value(k, DbObjectRights.int_to_rights_hash(v.to_i))
					else
					(silent) ? @fields[k.to_sym][:value] = v : self.set_field_value(k, v)
					end
				elsif (k.to_s == 'id') || (k.to_s == '_id')
					@id = v.to_s
				end
			}
			if silent #TODO: Temporary. All tables need to convert right int to right hash
				save_to_db
			end
			self.loaded = true
			return self
		end

		# Retrieves the object data from the database and loads it in this object using load_from_hash.
		# sets values directly to avoid validation and :changed being set
		# :category: Database methods
		def load_from_db
			data = @object_collection.find_one('_id' => BSON::ObjectId(@id)).to_a
			# raise NullObjectError.new if data.empty?
			return self.load_from_hash(data, true)
		end

		# Saves all object data to the database.
		# :category: Database methods
		def save_to_db
			is_new = self.id.nil?
			data = {}
			@fields.each { |key, options|
				data[key] = options[:value] if (is_new || options[:changed])
			}
			self.on_save_data(data)
			return self if (data.empty?)

			data.stringify_keys!
			if is_new
				@id = @object_collection.insert(data).to_s
			else
				@object_collection.update({_id: BSON::ObjectId(self.id)}, {'$set' => data}) if (!data.empty?)
			end
			@fields.each { |_, options| options[:changed] = false }
			@options[:tree].new.refresh if @options.has_key?(:tree)
			return self
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
			@object_collection.remove({_id: BSON::ObjectId(self.id)})
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