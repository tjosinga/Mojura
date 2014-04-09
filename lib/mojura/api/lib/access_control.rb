require 'api/lib/dbobject_rights'

module MojuraAPI

	module AccessControl
		extend self

		# Structure: group_rights[group][module][object_name][right] = boolean
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

		def get_group_rights
			@group_rights
		end

		def set_role_right(groupid, module_name, object_name, right, value)
			groupid = groupid.to_s
			module_name = module_name.to_s
			object_name = object_name.to_s.gsub(/^(\w+::)*/, '').downcase
			@group_rights[groupid] ||= {}
			@group_rights[groupid][module_name] ||= {}
			@group_rights[groupid][module_name][object_name] ||= {}
			if (value.nil?)
				@group_rights[groupid][module_name][object_name].delete(right)
				@group_rights.delete_if { | group |
					@group_rights[group].delete_if { | module_name |
						@group_rights[group][module_name].delete_if { | object_name |
							@group_rights[group][module_name][object_name].size == 0
						}
						module_name.size == 0
					}
					group.size == 0
				}
			else
				@group_rights[groupid][module_name][object_name][right] = value
			end
		end

		def get_role_right(groupid, module_name, object_name, right)
			object_name = object_name.to_s.gsub(/^(\w+::)*/, '').downcase
			return @group_rights[groupid.to_s][module_name.to_s][object_name][right] rescue nil
		end


		#-------------------------------------------------------------------------------------------------------------------

		def has_rights?(right, object, user = nil, ignore_admin_check = false)
			user ||= API.current_user
			return true if user.is_admin && !ignore_admin_check
			return has_role_based_owner_rights?(right, object, user)
		end

		private

		def has_role_based_owner_rights?(right, object, user)
			has_right = get_role_right(:owners, object.module, object.class, user)
			return (has_right.nil?) ? has_role_based_group_rights?(right, object, user) : has_right
		end

		def has_role_based_group_rights?(right, object, user)
			group_right = ((right == :create) && (object.id.nil?)) ? false : nil
			user.groupids.each { | groupid |
				val = get_role_right(groupid, object.module, object.class.name, right)
				group_right = (group_right.is_a?(TrueClass)) || val unless val.nil?
			}
			return (group_right.nil?) ? has_object_based_guest_rights?(right, object, user) : group_right
		end

		# Checks rights if user is a guest
		def has_object_based_guest_rights?(right, object, user)
			if user.id.nil?
				return object.rights[:guests][right]
			end
			return has_object_based_owner_rights?(right, object, user)
		end

		# Checks rights if user is the owner of the object
		def has_object_based_owner_rights?(right, object, user)
			if (object.userids.include?(user.id))
				return object.rights[:owners][right]
			end
			return has_object_based_group_rights?(right, object, user)
		end

		# Checks rights if user is in the same group as the object
		def has_object_based_group_rights?(right, object, user)
			if (object.groupids & user.groupids).size > 0
				return object.rights[:groups][right]
			end
			return has_object_based_other_users_rights?(right, object)
		end

		# Checks rights if user is logged in, but not owner and not in a intersecting group
		def has_object_based_other_users_rights?(right, object)
			return object.rights[:users][right]
		end

	end

end