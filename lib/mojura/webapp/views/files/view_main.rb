require 'uri'

module MojuraWebApp

	class FilesView < BaseView

		attr_reader :folderid, :modals

		def initialize(options = {})
      @folderid = options[:folderid].to_s
      @folderid = WebApp.page.request_params[:folderid].to_s if (@folderid == '')
      @folderid = options[:root_folderid].to_s if (@folderid == '')
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
      data[:root_folderid] = options[:root_folderid].to_s
      data[:has_description] = (!data[:description][:html].empty?) rescue false
      data[:is_base_folder] = (@folderid == 'root') || (@folderid == data[:root_folderid])
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
			@modals = [{id: 'modalAddFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_add'), title: WebApp.locale_str('files', 'action_add_file'), icon: 'fa-plus'},
			           {id: 'modalEditFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_edit'), title: WebApp.locale_str('files', 'action_edit_file'), icon: 'fa-pencil'},
			           {id: 'modalExtractFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('files', 'action_extract'), title: WebApp.locale_str('files', 'action_extract_file'), icon: 'fa-archive'},
			           {id: 'modalDeleteFile', btn_class: 'btn-danger', btn_title: WebApp.locale_str('system', 'action_delete'), title: WebApp.locale_str('files', 'action_delete_file'), icon: 'fa-trash-o'},
			           {id: 'modalAddFolder', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_add'), title: WebApp.locale_str('files', 'action_add_folder'), icon: 'fa-plus'},
			           {id: 'modalEditFolder', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_edit'), title: WebApp.locale_str('files', 'action_edit_folder'), icon: 'fa-pencil'},
			           {id: 'modalDeleteFolder', btn_class: 'btn-danger', btn_title: WebApp.locale_str('system', 'action_delete'), title: WebApp.locale_str('files', 'action_delete_folder'), icon: 'fa-trash-o'}]

			WebApp.page.include_template_file('template_files_folders_container', 'webapp/views/files/view_files_folders.mustache')
			WebApp.page.include_template_file('template-add-edit-file', File.dirname(__FILE__) + '/view_file_add_edit.mustache')
			WebApp.page.include_template_file('template-add-edit-folder', File.dirname(__FILE__) + '/view_folder_add_edit.mustache')
			WebApp.page.include_template_file('template-extract-file', File.dirname(__FILE__) + '/view_file_extract.mustache')
			WebApp.page.include_template_file('template-delete-file', File.dirname(__FILE__) + '/view_file_delete.mustache')
			WebApp.page.include_template_file('template-delete-folder', File.dirname(__FILE__) + '/view_folder_delete.mustache')

			WebApp.page.include_script("FilesView.setCurrentFolderId('#{folderid}', true);") if (@folderid != 'root')
		end

	end

	WebApp.register_view('files', FilesView, :min_col_span => 2)

end