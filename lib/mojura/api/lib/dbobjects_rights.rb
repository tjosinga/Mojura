module MojuraAPI

	# DbObjectsRight is a mixin module for DbObjects and automatically gives it rights support when added.
	# DbObjects will include this module automatically based on the class of a single item
	# :category: DbObject
	module DbObjectsRights

		def get_rights_where(user)
			if (user.nil?) || (user.id.nil?) || (user.id == '')
				result = {'right.guests.read' => true}
			elsif !user.administrator?
				groupids = user.groupids
				users_rights_where = {'right.users.read' => true}
				owner_rights_where = {'$and' => [{userids: user.id}, {'right.owners.read' => true}]}
				result = {'$or' => [users_rights_where, owner_rights_where]}
				result['$or'] << {'$and' => [{groupids: {'$in' => groupids}}, {'right.groups.read' => true}]} if (groupids.count > 0)
			else
				result = {}
			end
			return result
		end

		def update_where_with_rights(where = {})
			## insert right control here to where
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