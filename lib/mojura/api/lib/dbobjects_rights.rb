module MojuraAPI

	# DbObjectsRight is a mixin module for DbObjects and automatically gives it rights support when added.
	# DbObjects will include this module automatically based on the class of a single item
	# :category: DbObject
	module DbObjectsRights

		def get_rights_where(user)
			if (user.nil?) || (user.id.nil?) || (user.id == '')
				# The comparison with 0x7044 is temporarily, for backwards compatibility.
				result = {'$or' => [{'rights.guests.read' => true}, {'rights' => 0x7044}]}
			elsif !user.administrator?
				groupids = user.groupids
				users_rights_where = {'rights.users.read' => true}
				owner_rights_where = {'$and' => [{userids: user.id}, {'rights.owners.read' => true}]}
				result = {'$or' => [users_rights_where, owner_rights_where]}
				result['$or'] << {'$and' => [{groupids: {'$in' => groupids}}, {'rights.groups.read' => true}]} if (groupids.count > 0)
			else
				result = {}
			end
			return result
		end

		def update_where_with_rights(where = {})
			user = (!@options[:user].nil?) ? @options[:user] : API.current_user
			rights_where = get_rights_where(user)
			if rights_where != {}
				if (!where.nil?) && (where != {})
					where = {'$and' => [where, rights_where] }
				else
					where = rights_where
				end
			end
			return where
		end
	end

end