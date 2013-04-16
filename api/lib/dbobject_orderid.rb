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
		def reorder_before_save(query = {})
			query ||= {}
			count = @object_collection.find(query).count()

			if (@id.nil?) || (@fields[:orderid][:value] >= count)
				@fields[:orderid][:value] = count
			else
				new = @fields[:orderid][:value]
				old = @fields[:orderid][:orig_value]
				if new == 0
					amount = 1
					# All orderids needs to be increased
				elsif old < new
					amount = -1
					query[:orderid] = {'$gt' => old, '$lte' => new}
				else
					amount = 1
					query[:orderid] = {'$gte' => new, '$lt' => old}
				end
				@object_collection.update(query, {'$inc' => {orderid: amount}}, {multi: true})
			end
		end

	end


end