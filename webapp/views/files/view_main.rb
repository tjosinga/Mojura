require 'uri'

module MojuraWebApp

	class FilesView < BaseView

		include Editor

		attr_reader :folderid, :modals

		def initialize(options = {})
			@folderid = WebApp.page.request_params[:folderid].to_s
			@folderid = 'root' if (@folderid == '')
			params = {}
			params[:folderid] = @folderid if (!@folderid.nil?)
			begin
				data = WebApp.api_call("files/folders/#{@folderid}", params)
			rescue APIException => _
				data = {}
			end
			super(options, data)
			data[:files] ||= []
			@data[:files].map! { |item|
				item[:api_url].gsub!(/files/, 'files')
				item[:file_url].gsub!(/files/, 'files')
				item[:thumb_url].gsub!(/files/, 'files') if (item.include?(:thumb_url))
				item[:is_image] = (item[:mime_type].include?('image')) if !item[:mime_type].nil?
				item[:is_archive] = (item[:mime_type] == 'application/zip') if !item[:mime_type].nil?
				item
			}
			@modals = [{id: 'modalAddFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_add'), title: WebApp.locale_str('files', 'action_add_file')},
			           {id: 'modalEditFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_edit'), title: WebApp.locale_str('files', 'action_edit_file')},
			           {id: 'modalExtractFile', btn_class: 'btn-primary', btn_title: WebApp.locale_str('files', 'action_extract'), title: WebApp.locale_str('files', 'action_extract_file')},
			           {id: 'modalDeleteFile', btn_class: 'btn-danger', btn_title: WebApp.locale_str('system', 'action_delete'), title: WebApp.locale_str('files', 'action_delete_file')},
			           {id: 'modalAddFolder', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_add'), title: WebApp.locale_str('files', 'action_add_folder')},
			           {id: 'modalEditFolder', btn_class: 'btn-primary', btn_title: WebApp.locale_str('system', 'action_edit'), title: WebApp.locale_str('files', 'action_edit_folder')},
			           {id: 'modalDeleteFolder', btn_class: 'btn-danger', btn_title: WebApp.locale_str('system', 'action_delete'), title: WebApp.locale_str('files', 'action_delete_folder')}]

			WebApp.page.include_template_file('template_files_folders_container', 'webapp/views/files/view_files_folders.mustache')
			WebApp.page.include_template_file('template-add-edit-file', File.dirname(__FILE__) + '/view_file_add_edit.mustache')
			WebApp.page.include_template_file('template-add-edit-folder', File.dirname(__FILE__) + '/view_folder_add_edit.mustache')
			WebApp.page.include_template_file('template-extract-file', File.dirname(__FILE__) + '/view_file_extract.mustache')
			WebApp.page.include_template_file('template-delete-file', File.dirname(__FILE__) + '/view_file_delete.mustache')
			WebApp.page.include_template_file('template-delete-folder', File.dirname(__FILE__) + '/view_folder_delete.mustache')

			WebApp.page.include_script("FilesView.setCurrentFolderId('#{folderid}', true);") if (@folderid != 'root')
		end

		def is_base_folder
			(@folderid.nil?) || (@folderid == 'root')
		end

	end

	WebApp.register_view('files', FilesView, :min_col_span => 6)

end