require 'uri'

module MojuraWebApp

	class FilesView < BaseView

		attr_reader :folderid, :modals

		def initialize(options = {})
      @folderid = options[:folderid].to_s
      @folderid = WebApp.page.request_params[:folderid].to_s if (@folderid == '')
      @folderid = options[:base_folderid].to_s if (@folderid == '')
			@folderid = 'root' if (@folderid == '')
			params = {}
			params[:folderid] = @folderid
			begin
				data = WebApp.api_call("files/folder/#{@folderid}", params)
			rescue APIException => _
				data = {}
      end
      data[:hide_admin] = options[:hide_admin].to_s == 'true'
      data[:hide_folders] = options[:hide_folders].to_s == 'true'
      data[:hide_breadcrumbs] = options[:hide_breadcrumbs].to_s == 'true'
      data[:hide_icons] = options[:hide_icons].to_s == 'true'
      data[:hide_extensions] = options[:hide_extensions].to_s == 'true'
      data[:base_folderid] = options[:base_folder].to_s
      data[:has_description] = (!data[:description][:html].empty?) rescue false
      data[:is_base_folder] = (@folderid == 'root') || (@folderid == data[:base_folderid])
      options[:uses_editor] = true
			super(options, data)
			data[:files] ||= []
			@data[:files].map! { |item|
        item[:title].chomp!(File.extname(item[:title])) if data[:hide_extensions]
				item[:api_url].gsub!(/files/, 'files')
				item[:file_url].gsub!(/files/, 'files')
				item[:thumb_url].gsub!(/files/, 'files') if (item.include?(:thumb_url))
				item[:is_image] = (item[:mime_type].include?('image')) if !item[:mime_type].nil?
				item[:is_archive] = (item[:mime_type] == 'application/zip') if !item[:mime_type].nil?
				item
			}
			WebApp.page.include_template_file('template_files_folders_container', 'webapp/views/files/view_files_folders.mustache')
      if (WebApp.current_user.logged_in?)
				WebApp.page.include_template_file('template-files-add-edit-file', 'webapp/views/files/view_file_add_edit.mustache')
				WebApp.page.include_template_file('template-files-add-edit-folder', 'webapp/views/files/view_folder_add_edit.mustache')
				WebApp.page.include_template_file('template-files-extract-file', 'webapp/views/files/view_file_extract.mustache')
				WebApp.page.include_template_file('template-files-delete-file', 'webapp/views/files/view_file_delete.mustache')
				WebApp.page.include_template_file('template-files-delete-folder', 'webapp/views/files/view_folder_delete.mustache')
				WebApp.page.include_locale(:system)
				WebApp.page.include_locale(:files)
      end

			WebApp.page.include_script("FilesView.setCurrentFolderId('#{folderid}', false);") if (@folderid != 'root')
		end

	end

	WebApp.register_view('files', FilesView, :min_col_span => 2)

end