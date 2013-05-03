require 'api/lib/dbobject'
require 'api/lib/dbobjects'

module MojuraAPI

	class Group < DbObject

		include DbObjectRights

		def initialize(id = nil)
			super('groups', id)
		end

		def load_fields
			yield :name, String, :required => true
			yield :group_rights, Array, :extended_only => true
			yield :description, String, :extended_only => true
		end

		def to_a(compact = false)
			result = super
			result[:groups_url] = API.api_url + "groups/#{self.id}/members"
			return result
		end

		def add_right(mod_name, right)
			@fields[:group_rights][:value] ||= []
			@fields[:group_rights][:value][mod_name] ||= []
			unless @fields[:group_rights][:value][mod_name].include?(right)
				@fields[:group_rights][:value][mod_name].push(right)
				@fields[:group_rights][:changed] = true
			end
		end

		def remove_right(mod_name, right)
			@fields[:group_rights][:value] ||= []
			@fields[:group_rights][:value][mod_name] ||= []
			if @fields[:group_rights][:value][mod_name].include?(right)
				@fields[:group_rights][:value][mod_name].delete(right)
				@fields[:group_rights][:changed] = true
			end
		end

	end


	class Groups < DbObjects

		include DbObjectsRights

		def initialize(where = {}, options = {})
			options[:sort] = {name: 1} if (options[:sort].nil?)
			super('groups', Group, where, options)
		end

	end


end



