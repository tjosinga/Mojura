module MojuraAPI

	# DbObjectsRight is a mixin module for DbObjects and automatically gives it rights support when added.
	# :category: DbObject
	module DbObjectsRights

		def get_rights_where(user)
			if (user.nil?) || (user.id.nil?) || (user.id == '')
				result = {'$where' => '(this.right & 0x0004) == 0x0004'}
			elsif !user.is_admin
				groupids = user.groupids
				users_rights_where = {'$where' => '(this.right & 0x0040) == 0x0040'}
				owner_rights_where = {'$and' => [{ownerid: user.id}, {'$where' => '(this.right & 0x4000) = 0x4000'}]}
				result = {'$or' => [users_rights_where, owner_rights_where]}
				result['$or'] << {'$and' => [{'$in' => groupids}, {'$where' => '(this.right & 0x0400) = 0x0400'}]} if (groupids.count > 0)
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
					where = {'$and' => [where, rights_where]}
				else
					where = rights_where
				end
			end
			return where
		end
	end

end