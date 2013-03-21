#noinspection RubyResolve,RubyResolve
require 'tempfile'
require 'api/lib/dbobjects'
require 'api/lib/dbtree'
require 'mini_magick'
require 'exifr'
require 'zipruby'

# NB: Note that the objects are called DbFile(s) and DbFolder(s). Otherwise it would conflict with the File core class. Namespaces could fix it, but that's not


module MojuraAPI

	class DbFile < DbObject

		include DbObjectRights

		def initialize(id = nil)
			#making sure the following folders exists
			FileUtils.mkdir_p('uploads/files/image_cache')
			FileUtils.mkdir_p('uploads/files/originals')
			super('files_files', id, {module_name: 'files'})
		end

		def load_fields
			yield :folderid, BSON::ObjectId, :required => false
			yield :title, String, :required => true
			yield :sort_title, String, :required => true, :hidden => true #this field is needed because MongoDb doesn't natural sorting...
			yield :mime_type, String, :required => false
			yield :extension, String, :required => false
			yield :filesize, Integer, :required => false, :extended_only => true
			yield :img_width, Integer, :required => false, :extended_only => true
			yield :img_height, Integer, :required => false, :extended_only => true
			yield :description, RichText, :required => false
		end

		def delete_from_db
			File.unlink(self.get_real_filename)
			super
		end

		def get_real_filename(options = {})
			filename = "uploads/files/originals/#{@id}"
			if self.is_image?
				size = (options[:size] || 0)
				type = (options[:type] || 'auto')
				auto_create = options[:auto_create]
				size = 1024 if (size > 1024)
				if size > 0
					filename = "uploads/files/image_cache/#{@id}_#{size}_#{type}"
					self.resize_image(size, type, filename) if (auto_create) && (!File.exists?(filename))
				end
			end
			return filename
		end

		def save_uploaded_file(tempfile, save = true)
			self.extension = File.extname(self.title).downcase
			self.mime_type = Rack::Mime.mime_type(self.extension)
			filename = self.get_real_filename
			FileUtils.mv(tempfile, filename)
			FileUtils.chmod(0777, filename)
			if self.is_image?
				self.resize_image(800, 'auto') # force resizing of images to 800
				self.rotate('auto')
				self.get_real_filename(:size => 128, :auto_create => true) # force creation of thumb
			end
			self.mime_type = Rack::Mime.mime_type(self.extension)
			self.filesize = File.size(filename)
			self.save_to_db if (save)
		end

		def rotate(degrees = 'auto', dest_filename = nil)
			orig_filename = self.get_real_filename
			dest_filename ||= orig_filename

			if (degrees == 'auto') && ((self.extension == '.jpg') || (self.extension == '.jpeg'))
				image_exif = EXIFR::JPEG.new(orig_filename).exif
				degrees = (image_exif[:orientation] == EXIFR::TIFF::RightTopOrientation) ? '90>' : '-90>' if (!image_exif.nil?)
			end

			begin
				image = MiniMagick::Image.open(orig_filename)
				image.rotate(degrees)
				image.write(dest_filename)
			rescue
				# Do nothing
			end
		end

		def resize_image(size, type = 'auto', dest_filename = nil)
			return false if (!self.is_image?)
			orig_filename = self.get_real_filename
			dest_filename ||= orig_filename
			size = 1024 if (size > 1024)

			resize_str = case type
				             when 'width' then
					             "#{size}>"
				             when 'height' then
					             "x#{size}>"
				             when 'cropped' then
					             "#{size}x#{size}^"
				             else
					             "#{size}x#{size}>" # i.e. auto
			             end

			image = MiniMagick::Image.open(orig_filename)
			image.resize(resize_str)
			if type == 'cropped'
				image.gravity('center')
				image.crop("#{size}x#{size}+0+0")
			end
			if (self.extension == '.bmp') && (orig_filename == dest_filename)
				image.format('jpg')
				self.extension = '.jpg'
				self.mime_type = Rack::Mime.mime_type(self.extension)
			end
			image.write(dest_filename)
			image.destroy!
		end

		def to_a(compact = false)
			result = super
			result[:file_url] = API.api_url + "files/#{self.id}/download"
			if !self.is_image?
				result.delete(:img_width)
				result.delete(:img_height)
			else
				result[:thumb_url] = API.api_url + "files/#{self.id}/download?type=thumb"
			end
			return result
		end

		def is_image?
			((!self.mime_type.nil?) && (self.mime_type[0..5] == 'image/') && (!self.mime_type.include?('icon')))
		end

		def is_archive?
			((!self.mime_type.nil?) && (self.mime_type.include?('application/zip')))
		end

		def extract
			base_folder = DbFolder.new
			base_folder.title = File.basename(self.title, self.extension)
			base_folder.rights = self.rights
			base_folder.parentid = self.folderid
			base_folder.save_to_db
			folders = {'.' => base_folder}

			Zip::Archive.open(self.get_real_filename) do |zip|
				# Creates all folders before all files are extracted
				zip.map { |f|
					if f.directory?
						name = File.basename(f.name)
						if !folders.has_key?(name)
							folder = DbFolder.new
							folder.rights = self.rights
							folder.parentid = (folders[File.dirname(f.name)].id || base_folder.id)
							folder.title = name
							folder.save_to_db
							folders[name] = folder
						end
					end
				}

				# Extracts all files
				zip.map { |f|
					if !f.directory?
						tmpfile = Tempfile.new('mojura_unzip', '/tmp')
						begin
							tmpfile.write(f.read)
							tmpfile.close
							file = DbFile.new
							file.folderid = (folders[File.dirname(f.name)].id || base_folder.id)
							file.rights = self.rights
							file.title = File.basename(f.name)
							file.save_to_db
							file.save_uploaded_file(tmpfile.path, true)
						ensure
							tmpfile.unlink
						end
					end
				}
			end
			return base_folder
		end


	end


	class DbFiles < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] = {title: 1} if (!options.include?(:sort))
			super('files_files', DbFile, where, options)
		end

	end


	class DbFolder < DbObject

		include DbObjectRights

		def initialize(id = nil)
			super('files_folders', id, {module_name: 'files', api_url: 'files/folder', tree: DbFolderTree})
		end

		def load_fields
			yield :parentid, BSON::ObjectId, :required => false, :default => nil
			yield :title, String, :required => true, :default => ''
			yield :description, RichText, :required => false, :default => '', :extended_only => true
		end

		def delete_from_db
			subfolders = DbFolders.new({parentid: BSON::ObjectId(self.id)})
			subfolders.each { |subfolder| subfolder.delete_from_db }
			files = DbFiles.new({folderid: BSON::ObjectId(self.id)})
			files.each { |file| file.delete_from_db }
			super
		end

	end


	class DbFolders < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] = {title: 1} if (!options.include?(:sort))
			super('files_folders', DbFolder, where, options)
		end

	end


	class DbFolderTree < DbTree

		def initialize
			super('files_folders', true, [:title], 'files/folder')
		end

		def on_object_to_tree!(object, info)
			info[:api_url] = 'files/?folderid=' + info[:id]
		end

	end


end