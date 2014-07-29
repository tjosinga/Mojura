require 'api/resources/users/users.objects'

module MojuraAPI

	class GroupRightsResource < RestResource

		def name
			'Group rights'
		end

		def description
			'Shows all possible global rights. Each object has its own rights after creation. ' +
			'Global rights are mainly used for fetching creation rights.'
		end

		#noinspection RubyUnusedLocalVariable
		def uri_id_to_regexp(id_name)
			return '[0-9a-f]{24}'
		end

		def all(params)
			return API.module_rights(params[:module])
		end

		def get(params)
			Group.new(params[:ids][0]).group_rights.to_hash
		end

		def put(params)
			group = Group.new(params[:ids][0])
			rights = params[:rights].to_s.split(',')
			rights.each { | s |
				mod_name, right = s.split('_', 2)
				group.add_right(mod_name, right)
			}
			group.save_to_db
			return group.group_rights
		end

		def delete(params)
			group = Group.new(params[:ids][0])
			rights = params[:rights].to_s.split(',')
			rights.each { |s|
				mod_name, right = s.split('_', 2)
				group.remove_right(mod_name, right)
			}
			group.save_to_db
			return group.group_rights
		end

		def all_conditions
			{
				description: 'Returns a list of all rights per module.'
			}
		end

		def get_conditions
			{
				description: 'Returns a list rights of the given group.'
			}
		end

		def put_conditions
			{
				description: 'Adds multiple rights to the given group',
				attributes: {
					rights: {required: true, type: String, description: 'Comma seperated list of rights in format [module]_[right], i.e. users_create'}
				}
			}
		end

		def delete_conditions
			{
				description: 'Removes multiple rights from the given group.',
				attributes: {
					rights: {required: true, type: String, description: 'Comma seperated list of rights in format [module]_[right], i.e. users_create'}
				}
			}
		end


	end

	API.register_resource(GroupRightsResource.new('groups', 'rights', '[groupid]/rights'))
end
