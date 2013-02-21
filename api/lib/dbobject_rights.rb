module MojuraAPI

  module DbObjectRights

    @rights_default = 0x7044

    def load_rights_fields
      yield :userid,  BSON::ObjectId, :required => true,  :group => :rights, :default => API.current_user.id
      yield :groupid, BSON::ObjectId, :required => false, :group => :rights, :default => nil
      yield :right,   Integer,        :required => true,  :group => :rights, :default => @rights_default
    end

    def user_has_right(right, user = nil)
      user = API.current_user if user.nil?
      return user.has_object_right(right, self.userid, self.groupid, self.right)
    end

    def rights_as_bool(user = nil)
      user = API.current_user if user.nil?
    	return	{custom: self.user_has_right(RIGHT_CUSTOM, user),
               read: self.user_has_right(RIGHT_READ, user),
               update: self.user_has_right(RIGHT_UPDATE, user),
               delete: self.user_has_right(RIGHT_DELETE, user)}
    end

  end

end