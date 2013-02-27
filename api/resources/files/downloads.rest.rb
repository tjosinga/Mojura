require 'api/lib/restresource'
require 'api/resources/files/files.objects'

module MojuraAPI

	class FileDownloadResource < RestResource

		def name
			'Downloads'
		end

		def description
			'Download resource for files, which are a core object in Mojura.'
		end

		def get(params)
			file = DbFile.new(params[:ids][0])
			options = {}
			if file.is_image?
				options[:auto_create] = true
				if params[:type] == 'thumb'
					options[:size] = 128
				elsif params[:type] == 'avatar'
					options[:size] = 128
					options[:type] = 'cropped'
				else
					options[:size] = params[:size] if params.include?(:size)
					options[:type] = params[:type] || 'auto'
				end
			end
			return API.send_file(file.get_real_filename(options), :filename => file.title, :mime_type => file.mime_type)
		end

		def get_conditions
			{
				description: 'Returns the filedata of the specified file.',
				attributes: {
					size: {required: false, type: Integer, description: 'For images: Maximum size (width or height) of the image. Needs to be specified if use auto, height, width or cropped type.'},
					type: {required: false, type: String, description: 'For images: Type of resizing. Could be one of the following types thumb, avatar, auto, height, width or cropped. Default is auto. The thumb and avatar types use predefined sizes.'},
				}
			}
		end

	end

	API.register_resource(FileDownloadResource.new('files', 'downloads', '[fileid]/download'))

end