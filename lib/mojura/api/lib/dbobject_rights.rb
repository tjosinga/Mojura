module MojuraAPI

	module DbObjectRights

		def rights_default
			class_name = self.class.name[11..-1].to_sym
			Settings.get_h(:object_rights, @object_module)[class_name] || 0x7044
		end

		def load_rights_fields
			yield :userids, Array, :required => true, :group => :rights, :default => [ API.current_user.id ]
			yield :groupids, Array, :required => false, :group => :rights, :default => []
			yield :right, Integer, :required => true, :group => :rights, :default => rights_default
		end

		def user_has_right?(right, user = nil)
			user ||= API.current_user
			return user.has_object_right?(right, self.userids, self.groupids, self.right.to_i)
		end

		def rights_as_bool(user = nil)
			user ||= API.current_user
			return {custom: self.user_has_right?(RIGHT_CUSTOM, user),
			        read: self.user_has_right?(RIGHT_READ, user),
			        update: self.user_has_right?(RIGHT_UPDATE, user),
			        delete: self.user_has_right?(RIGHT_DELETE, user)}
		end

	end

end