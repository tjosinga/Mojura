module MojuraAPI

	module DbObjectRights

		def rights_default
			DbObjectRights.int_to_rights_hash(Settings.get_h(:object_rights, @module)[self.class.name[11..-1].to_sym] || 0x7044)
		end

		def load_rights_fields
			yield :userids, Array, :required => true, :group => :rights, :default => [ API.current_user.id ]
			yield :groupids, Array, :required => false, :group => :rights, :default => []
			yield :rights, Hash, :required => true, :group => :rights, :default => rights_default
		end

		def current_user_has_right?(right)
			user_has_right?(right, API.current_user)
		end

		def user_has_right?(right, user)
			return AccessControl.has_rights?(right, self, user)
		end

		def rights_as_bool(user = nil)
			user ||= API.current_user
			return {custom: self.user_has_right?(RIGHT_CUSTOM, user),
			        read: self.user_has_right?(RIGHT_READ, user),
			        update: self.user_has_right?(RIGHT_UPDATE, user),
			        delete: self.user_has_right?(RIGHT_DELETE, user)}
		end

		def DbObjectRights.int_to_rights_hash(i)
			mask = 1
			result = {}
			[:guests, :users, :groups, :owners].each { | level |
				[:delete, :update, :read, :custom].each { | action |
					result[level] ||= {}
					result[level][action] = i & mask > 0
					mask = mask << 1
				}
			}
			return result
		end

		def DbObjectRights.rights_hash_to_int(hsh)
			result = 0
			hsh ||= {}
			hsh.symbolize_keys!
			[:owners, :groups, :users, :guests].each { | level |
				[:custom, :read, :update, :delete].each { | action |
					hsh[level] ||= {}
					result = result << 1
					result += (hsh[level][action].is_a?(TrueClass) ? 1 : 0)
				}
			}
			return result
		end

	end

end