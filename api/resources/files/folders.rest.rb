require 'api/resources/files/files.objects'

module MojuraAPI

	class FolderResource < RestResource

		def name
			'Folders'
		end

		def description
			'Resource of folders, which are a core object in Mojura.'
		end

		def uri_id_to_regexp(id_name)
			"#{super}|root"
		end

		def all(params)
			path = (params.has_key?(:path)) ? params[:path] : ''
			if path != ''
#	    	full = (params.has_key?(:path)) ? params[:path] : ''
				result = DbFolderTree.new.nodes_of_path(path)
			else
				depth  = (params.has_key?(:depth)) ? params[:depth].to_i : 2
				result = DbFolderTree.new.to_a(depth)
			end
			return result
		end

		def get(params)
			id                  = (params[:ids][0] == 'root') ? nil : params[:ids][0]
			oid                 = (!id.nil?) ? BSON::ObjectId(id) : nil
			result              = DbFolder.new(id).to_a
			#TODO: Check rights
			result[:parents]    = DbFolderTree.new.parents_of_node(id)
			result[:subfolders] = DbFolders.new({parentid: oid}).to_a
			result[:files]      = DbFiles.new({folderid: oid}).to_a
			return result
		end

		def put(params)
			DbFolder.new.load_from_hash(params).save_to_db.to_a
			#TODO: Check rights
		end

		def post(params)
			id = (params[:ids][0] == 'root') ? nil : params[:ids][0]
			DbFolder.new(id).load_from_hash(params).save_to_db.to_a
			#TODO: Check rights
		end

		def delete(params)
			id = (params[:ids][0] == 'root') ? nil : params[:ids][0]
			DbFolder.new(id).delete_from_db
			#TODO: Check rights
			return [:success => true]
		end

		def all_conditions
			{
				description: 'Returns a tree of all folders.',
				attributes:  {
					depth: {required: false, type: Integer, description: 'The depth of the returned tree. If not specified, the whole tree is returned'},
					path:  {required: false, type: String, description: 'If a path (titles seperated with the \'/\' symbol) is given, a list of all folders on that path are returned. The last folder will be returned fully. Returns an 404 error if the folder does not exists. Each title should be \'urlencoded\'.'},
				}
			}
		end

		def put_conditions
			result = {
				description: 'Creates a folder and returns the object.',
				attributes:  {
					folderid: {required: false, type: BSON::ObjectId, description: 'The ID of the parent folder. If none is given, it\'s placed in the root of the tree.'},
					title:    {required: true, type: String, description: 'The title of the folder, preferably unique.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			result = {
				description: 'Returns the root folder or another specified folder, including all its files and subfolders.  Use \'files/folder/0\' to get the root folder.',
				attributes:  {
					folderid: {required: false, type: BSON::ObjectId, description: 'The ID of the folder. If 0 is given, the root folder will be used.'},
				}
			}
			return result
		end

		def post_conditions
			result =
				{
					description: 'Updates a folder with the given keys.',
					attributes:  self.put_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			result =
				{
					description: 'Deletes the folder and all its subfolders and files.',
				}
			return result
		end

	end

	API.register_resource(FolderResource.new('files', 'folders', 'folder/[folderid]'))

end