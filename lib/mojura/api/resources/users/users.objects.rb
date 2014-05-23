require 'openssl'
require 'crypt/blowfish'
require 'digest/md5'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	#making sure the following folders exists
	FileUtils.mkdir_p('uploads/users/avatars')

	class User < DbObject

		def initialize(id = nil)
			super('users', id)
			@loaded_groups = nil
		end

		def load_fields
			yield :username, String, :required => true, :validations => {matches_regexp: /^[a-zA-Z0-9]+[\w\.-]*$/}, :searchable => true
			yield :password, String, :required => true, :hidden => true
			yield :email, String, :required => true, :extended_only => true, :validations => {is_email: true}
			yield :firstname, String, :required => true, :searchable => true, :searchable_weight => 10
			yield :infix, String, :searchable => true
			yield :lastname, String, :required => true, :searchable => true, :searchable_weight => 10
			yield :is_admin, Boolean, :required => true, :default => false, :extended_only => true
			yield :groupids, Array, :default => [], :hidden => true
			yield :state, String, :default => :active
			yield :has_avatar, Boolean, :hidden => true
			yield :cookie_tokens, Hash, :default => {}, :hidden => true
		end

		def administrator?
			self.is_admin
		end

		# Returns the decrypted digest of the users password
		#
		# @return [String]
		def digest
			return Crypt::Blowfish.new('5t9WXHqboKGMDRZ3').decrypt_string([@fields[:password][:value]].pack('H*')).to_s
		end

		def on_save_data(data)
			if data.include?(:password) && !data[:password].nil?
				data[:password] = Crypt::Blowfish.new('5t9WXHqboKGMDRZ3').encrypt_string(data[:password]).unpack('H*')[0]
				@fields[:password][:value] = data[:password]
			end
		end

		def groups(force_reload = false)
			if @loaded_groups.nil? || force_reload
				groupids = []
				@fields[:groupids][:value].each { |id| groupids.push(BSON::ObjectId(id)) }
				@loaded_groups = Groups.new({_id: {'$in' => groupids}})
			end
			return @loaded_groups
		end

		def subscribe_to_group(groupid)
			unless @fields[:groupids][:value].include?(groupid)
				@fields[:groupids][:value].push(groupid)
				@fields[:groupids][:changed] = true
			end
		end

		def unsubscribe_from_group(groupid)
			if @fields[:groupids][:value].include?(groupid)
				@fields[:groupids][:value].delete_if { | id | id == groupid }
				@fields[:groupids][:changed] = true
			end
		end

		def current_user_has_right?(right)
			user_has_right?(right, API.current_user)
		end

		def user_has_right?(right, user)
			return AccessControl.has_rights?(right, self, user)
		end

		def valid_cookie_token?(token)
			@fields.include?(:cookie_tokens) && @fields[:cookie_tokens][:value].has_value?(token)
		end

		def generate_new_cookie_token
			return if (self.id.nil?) || (self.id == '')
			timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
			new_token = SecureRandom.hex(64)

			@fields[:cookie_tokens][:value] ||= {}
			@fields[:cookie_tokens][:value][timestamp] = new_token
			@fields[:cookie_tokens][:changed] = true
			API.headers['X-persist-username'] = self.username
			API.headers['X-persist-token'] = new_token

			# Delete all stored tokens older than two weeks
			old_timestamp = (Time.now - (60*60*24*14)).strftime('%Y-%m-%d %H:%M:%S')
			@fields[:cookie_tokens][:value].delete_if { | ts, _ | ts.to_s < old_timestamp }

			# Purge oldest as long as the set contains more than 50 tokens
			purge_count = @fields[:cookie_tokens][:value].length - 50
			while purge_count > 0
				@fields[:cookie_tokens][:value].shift
				purge_count -= 1
			end
			self.save_to_db
			return new_token
		end

		def fullname
			(firstname.to_s + ' ' + infix.to_s).strip + ' ' + lastname.to_s
		end

		def to_a(compact = false)
			result = super
			result[:fullname] = fullname

			if !self.id.nil?
				#TODO: create avatar support. If ready implement:
				if (has_avatar)
					result[:avatar] = API.api_url + "users/#{@id}/avatar?"
				else
					result[:avatar] = 'http://www.gravatar.com/avatar/' + Digest::MD5.hexdigest(self.email.to_s) + '?d=mm'
				end
				is_admin = API.current_user.administrator?
				unless compact
					result[:rights] = {
						update: false,
						delete: false
					}
					if API.current_user.logged_in?
						result[:rights][:subscribe] = true if is_admin || Settings.get_b(:has_subscribable_groups, :groups)
						result[:rights][:force_password] = true if is_admin
						result[:rights][:update] = is_admin || (API.current_user.id == @id)
						result[:rights][:delete] = is_admin || current_user_has_right?(:delete)
						result[:groups_url] = API.api_url + "users/#{@id}/groups"
					else
						[:is_admin, :state, :rights].each { | k | result.delete(k) }
					end
				end
			end

			setting = API.current_user.logged_in? ? :show_email_to_users : :show_email_to_guests
			unless API.current_user.administrator? ||
							(API.current_user.id == @id) ||
							Settings.get_b(setting, :users, false) ||
							current_user_has_right?(:update)
				result.delete(:email)
			end
			return result
		end

		# Resets the password and sends it to the know email address
		def reset_password
			#new_password =
			#new_digest = "#{this.username}:#{new_password}:#{realm}"
		end

		def logged_in?
			!id.nil? && (API.current_user.id == self.id)
		end

		def get_search_index_title_and_description
			[fullname, '']
		end

		def avatar_filename
			"uploads/users/avatars/#{@id}.jpg"
		end

		def save_avatar(tempfile, type)
			degrees = ''
			size = 256
			if (type.downcase == 'image/jpeg')
				image_exif = EXIFR::JPEG.new(tempfile).exif
				unless image_exif.nil?
					if (image_exif[:orientation] == EXIFR::TIFF::LeftTopOrientation)
						degrees = '90>'
					elsif (image_exif[:orientation] == EXIFR::TIFF::RightTopOrientation)
						degrees = '90>'
					elsif (image_exif[:orientation] == EXIFR::TIFF::RightBottomOrientation)
						degrees = '-90>'
					elsif (image_exif[:orientation] == EXIFR::TIFF::LeftBottomOrientation)
						degrees = '-90>'
					elsif (image_exif[:orientation] == EXIFR::TIFF::BottomRightOrientation)
						degrees = '180>'
					end
				end
			end
			begin
				image = MiniMagick::Image.open(tempfile)
				image.combine_options { | c |
					c.rotate(degrees) unless degrees.empty?
					c.resize("#{size}x#{size}^")
					c.gravity('center')
					c.crop("#{size}x#{size}+0+0")
				}
				image.format('jpg')
				image.write(avatar_filename)
			rescue
				# Do nothing
			end
			self.has_avatar = true
			save_to_db
		end

		def delete_avatar
			File.delete(avatar_filename) rescue true
			self.has_avatar = false
			save_to_db
		end

	end


	class Users < DbObjects

		def initialize(where = {}, options = {})
			super('users', User, where, options)
		end

		def get_rights_where(user = nil)
			user ||= API.current_user
			@options[:ignore_rights] = false unless @options.include?(:ignore_rights)
			if (!@options[:ignore_rights]) && (!user.nil?) && (!user.current_user_has_right?(:read))
				#TODO: implement state and set active to current users
				result = {_id: user.id} #{'$and' => [{state: 'active'}, {_id: user.id}]}
			else
				result = {} #{state: 'active'}
			end
			return result
		end

	end


end