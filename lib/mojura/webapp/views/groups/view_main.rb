
module MojuraWebApp

	class GroupsView < BaseView

		def initialize(options = {})
			data = WebApp.api_call('groups')
			super(options, data)
			WebApp.page.include_template_file('template-groups-add-edit', 'webapp/views/groups/view_add_edit.mustache')
			WebApp.page.include_template_file('template-groups-edit-rights', 'webapp/views/groups/view_edit_rights.mustache')
			WebApp.page.include_template_file('template-groups-members', 'webapp/views/groups/view_members.mustache')
			WebApp.page.include_template_file('template-groups-delete', 'webapp/views/groups/view_delete.mustache')
			WebApp.page.include_template_file('template-avatar-partial', 'webapp/views/groups/view_avatar_partial.mustache')
			WebApp.page.include_template_file('template-users-avatars', 'webapp/views/users/view_avatars.mustache')
			WebApp.page.include_locale('system');
			WebApp.page.include_locale('groups');
		end

		WebApp.register_view('groups', GroupsView)

	end


end