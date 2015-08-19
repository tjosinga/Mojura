require 'api/lib/dbobject'
require 'api/lib/dbobjects_rights'
require 'api/lib/dbobjects_locales'

module MojuraAPI

	# DbObjects represents an collection of DbObject objects.
	# :category: DbObject
	class DbObjects

		include Enumerable

		@collection = nil
		@objects = nil
		@item_class = nil

		attr_reader :db_col_name, :page, :pagesize, :count, :sort, :options

		def initialize(db_col_name, item_class, where = {}, options = {})
			self.class.send(:include, DbObjectsRights) if item_class.ancestors.include?(MojuraAPI::DbObjectRights)
			self.class.send(:include, DbObjectsLocales) if API.multilingual? && item_class.ancestors.include?(MojuraAPI::DbObjectLocales)
			@collection = MongoDb.collection(db_col_name)
			@objects = []
			@db_col_name = db_col_name
			@item_class = item_class
			@options = options
			@options ||= {}
			@page = (@options[:page] || 1)
			@page = 1 if @page < 1
			@pagesize = (@options[:pagesize] || 50)
			@pagesize = 100 if @pagesize < 1
			@sort = (@options[:sort] || {})
			@count = -1
			self.load_from_db(where)
		end

		def load_from_db(where)
			# sk = @page * @pagesize
			where = self.update_where_with_rights(where) if self.respond_to?(:update_where_with_rights)
			where = self.update_where_with_locales(where) if API.multilingual? && self.respond_to?(:update_where_with_locales)
			where.stringify_keys! if (where.is_a?(Hash))
			cursor = @collection.find(where)
			@count = cursor.count
			if !@sort.empty?
				srt = []
				@sort.each { |k, v|
					if (v == 'desc') || (v == -1) || (v == :desc)
						v = :desc
					else
						v = :asc
					end
					srt << [k, v]
				}
				cursor.sort(srt)
			end
			sk = (@page - 1) * @pagesize
			data = cursor.skip(sk).limit(@pagesize).to_a
			data.each { |v|
				object = @item_class.new
				object.load_from_hash(v, true)
				@objects << object
			}
			return self
		end

		def each
			@objects.each { |v| yield v }
		end

		def inspect
			@objects
		end

		def to_a(compact = true)
			result = []
			@objects.each { |obj| result << obj.to_h(compact) }
			return result
		end

	end

end