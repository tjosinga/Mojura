require 'mongo'
require 'api/lib/dataobject'
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

	class DbObject < DataObject

		include DbObjectSearchable

		@module = nil
		@collection = nil
		@loaded = false
		@options = nil

		attr_reader :id, :id_type, :loaded, :module

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

			super({})

			self.load_from_db if (!id.nil?)
		end

		def api_url
			@options[:api_url] + '/' + @id
		end

		def to_h(compact = false)
			result = {id: self.id}.merge(super)
			if ((result.has_key?(:rights)) && (self.class.include?(DbObjectRights)))
				result[:rights][:allowed] = rights_as_bool
				result[:rights][:rights] = DbObjectRights.rights_hash_to_int(result[:rights][:rights])
			end
			result[:api_url] = api_url if (compact)
			return result;
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

		def load_from_hash(values, silent = false)
			super
			if values.has_key?(:id) || values.has_key?(:_id) || values.has_key?('_id') || values.has_key?('_id')
				v = values[:id] || values[:_id] || values['_id'] || values['id']
				@id = (v.is_a?(BSON::Binary)) ? v.unpack('H*')[0] : v.to_s
			end
			return self
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

	end

end