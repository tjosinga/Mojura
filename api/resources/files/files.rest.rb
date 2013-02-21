require 'api/lib/restresource'
require 'api/resources/files/files.objects'
require 'api/resources/files/folders.rest'
require 'api/resources/files/downloads.rest'

module MojuraAPI

  class FileResource < RestResource

    def name
      'Files'
    end

    def description
      'Resource of files and folders, which are a core object in Mojura.'
    end

    def all(params)
      return paginate(params) { | options | DbFiles.new(self.filter(params), options) }
    end

    def put(params)
    	if (!params.include?(:title) || params[:title] == '') && (!params[:file].nil?)
				params[:title] = params[:file][:filename]
			end

			#TODO: Check rights
			file = DbFile.new.load_from_hash(params).save_to_db
			self.process_upload(file, params)
      return self.process_action(file, params[:action])
    end

    def get(params)
      file = DbFile.new(params[:ids][0])
			#TODO: Check rights
      return file.to_a
    end

    def post(params)
      file = DbFile.new(params[:ids][0])
			#TODO: Check rights
      file.load_from_hash(params)
      file.save_to_db
      return self.process_action(file, params[:action])
    end

    def process_upload(file, params)
			if (params.include?(:file)) && (!params[:file][:tempfile].nil?)
       	file.save_uploaded_file(params[:file][:tempfile].path)
      end
		end

		def process_action(file, action)
      if (action == 'extract') || (action == 'extract_delete')
        folder = file.extract
				file.delete_from_db if (action == 'extract_delete')
				return folder.to_a
	    end
	    return file.to_a
		end

    def delete(params)
      file = DbFile.new(params[:ids][0])
			#TODO: Check rights
      file.delete_from_db
      return [:success => true]
    end

    def all_conditions
      result = {
          description: 'Returns files all files regardless of the existing folders. For listing based on a folder structure, please use the \'files/folders\' section',
          attributes: page_conditions.merge(filter_conditions)
      }
      return result
    end

    def put_conditions
      result = {
          description: 'Creates a file and returns the object.',
          attributes: {
              folderid: {required: false, type: BSON::ObjectId, description: 'The ID of the parent folder. If none is given, it\'s placed in the root of the tree.'},
              title: {required: false, type: String, description: 'The title of the file, preferably unique. If none give, it will use the name of the uploaded file.'},
              file: {required: true, type: File, description: 'The file itself.'},
              action: {required: false, type: String, description: 'An action which is performed on the file. Possible values are: <ul><li><b>extract</b>: Extracts a zipfile.</li><li><b>extract_delete</b>: Extracts a zipfile and deletes it afterwards. NB: In this case the result is the new created folder.</li></ul>'},
          }
      }
      result[:attributes].merge(self.rights_conditions)
      result[:attributes].merge(self.tags_conditions)
      return result
    end

    def get_conditions
      {
          description: 'Returns a file with the specified fileid.',
      }
    end

    def post_conditions
      result =
      {
          description: 'Updates a file with the given keys.',
          attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
      }
      return result
    end

    def delete_conditions
      result =
      {
          description: 'Deletes the file.'
      }
      return result
    end

  end

  API.register_resource(FileResource.new('files', '', '[fileid]'))

end