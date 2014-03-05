module MojuraAPI

	module AccessControl
		extend self

		# Structure: role_based_rights[resource][type][right] = boolean
		# NB: A right may be true, false or nil. Nil means it skips to the next check.

		:true
		:false
		:skip

		@role_based_rights = {}

		def load
			@role_based_rights = Settings.get_h(:access_control, :core, {}, [:private])
		end

		def save
			Settings.set(:access_control, :core, :private)
		end

		def set_role_right(resource, type, value)

		end

		def get_role_right(resource, type)

		end

		#-------------------------------------------------------------------------------------------------------------------

		def has_rights?(rights, object, user = nil, ignore_admin_check = false)
			user ||= API.current_user
			return true if user.is_admin && !ignore_admin_check
			rights = [rights] unless rights.is_a?(Array)
			return has_role_based_owner_rights?(rights, object, user)
		end

		private

		def has_role_based_owner_rights?(rights, object, user)
			resource = (object.is_a?(Class)) ? object : object.class
			#TODO Add some magic here
			return has_role_based_group_rights?(rights, object, user)
		end

		def has_role_based_group_rights?(rights, object, user)
			resource = (object.is_a?(Class)) ? object : object.class
			#TODO Add some magic here
			right_code = rights.inject{ | sum, x | sum + x }
			return (object.is_a?(Class)) ? false : has_object_based_guest_rights?(right_code, object, user)
		end

		# Checks rights if user is a guest
		def has_object_based_guest_rights?(right_code, object, user)
			if user.id.nil?
				return (right_code & object.right) > 0
			end
			return has_object_based_owner_rights?(right_code, object, user)
		end

		# Checks rights if user is the owner of the object
		def has_object_based_owner_rights?(right_code, object, user)
			if (object.userids.include?(user.id))
				return ((right_code << 12) & object.right) > 0
			end
			return has_object_based_group_rights?(right_code, object, user)
		end

		# Checks rights if user is in the same group as the object
		def has_object_based_group_rights?(right_code, object, user)
			if (object.groupids & user.groupids).size > 0
				return ((right_code << 8) & object.right) > 0
			end
			return has_object_based_other_users_rights?(right_code, object)
		end

		# Checks rights if user is logged in, but not owner and not in a intersecting group
		def has_object_based_other_users_rights?(right_code, object)
			return ((right_code << 4) & object.right) > 0
		end

	end

end