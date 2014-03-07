module MojuraAPI

	module AccessControl
		extend self

		# Structure: group_rights[group][module][resource] = crud bits
		# NB: A result may be true, false or nil. Nil means it skips to the next check.

		@group_rights = {}

		def load
			@group_rights = Settings.get_h(:group_rights, :core, {}, [:private])
			@group_rights.symbolize_keys!
		end

		def save
			Settings.set(:group_rights, :core, :private)
			Settings.save_db_settings
		end

		def set_role_right(groupid, module_name, resource, right, value)
			groupid = groupid.to_sym
			module_name = module_name.to_sym
			resource = resource.to_sym
			right = right.to_sym
			@group_rights[groupid] ||= {}
			@group_rights[groupid][module_name] ||= {}
			@group_rights[groupid][module_name][resource] ||= {}
			@group_rights[groupid][module_name][resource][right] = value
		end

		def get_role_right(groupid, module_name, resource)
			return @group_rights[groupid.to_sym][module_name.to_sym][resource.to_sym] rescue nil
		end

		#-------------------------------------------------------------------------------------------------------------------

		def right_to_sym(right)
			case right
				when RIGHT_CREATE then :create
				when RIGHT_READ then :read
				when RIGHT_UPDATE then :update
				when RIGHT_DELETE then :delete
				when RIGHT_CUSTOM then :custom
			end
		end

		def sym_to_right(sym)
			case sym
				when :create then RIGHT_CREATE
				when :read then RIGHT_READ
				when :update then RIGHT_UPDATE
				when :delete then RIGHT_DELETE
				when :custom then RIGHT_CUSTOM
			end
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
			group_right = nil
			user.groupids.each { | groupid |

			}
			if
			return has_role_based_group_rights?(rights, object, user)
		end

		def has_role_based_group_rights?(rights, object, user)
			resource = (object.is_a?(Class)) ? object : object.class
			#TODO Add some magic here
			right_code = rights.inject{ | sum, x | sum + x }
			if (object.is_a?(Class))
				return false
			else
				return has_object_based_guest_rights?(right_code, object, user)
			end
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