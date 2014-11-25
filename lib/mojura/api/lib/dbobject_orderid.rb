module MojuraAPI

	# DbObjectOrderId is a mixin module for DbObject and adds sorting support for an object.
	# :category: DbObject
	module DbObjectOrderId

		@save_on_orderid_change = true

		# Adds an orderid field to the object
		def load_orderid_fields
			yield :orderid, Integer, :required => true, :default => 99999
		end

		# Reorders other objects to fit the new place of the current object
		def reorder_before_save(query = {}, object_in_same_range = true)
			query ||= {}
			sort ||= {orderid: 1}
			unless @id.nil?
				id = (@id_type == :binary) ? BSON::Binary.new([@id].pack('H*')) : BSON::ObjectId(@id)
				query[:_id] = {'$ne' => id}
			end
			objects = []
			@collection.find(query).sort(sort).each { | obj |
				objects << {'_id' => obj['_id'], 'orderid' => obj['orderid'] }
			}
			count = objects.count();

			if (@fields[:orderid][:value] <= 0)
				@fields[:orderid][:value] = 1
			elsif (@fields[:orderid][:value] >= count)
				count += 1
			  @fields[:orderid][:value] = count
			end

			i = 1
			objects.each { | obj |
				i += 1 if object_in_same_range && (i == @fields[:orderid][:value].to_i)
				@collection.update({'_id' => obj['_id']}, {'$set' => {'orderid' => i}}) if obj['orderid'].to_i != i
				API.log.info("Change order on #{@module}: #{obj['parentid']} from #{obj['orderid']} to #{i}") if obj['orderid'].to_i != i
				i += 1
			}
		end
	end


end