require 'openssl'
require 'crypt/blowfish'
require 'digest/md5'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class User < DbObject

		def initialize(id = nil)
			super('users', id)
			@loaded_groups = nil
		end

		def load_fields
			yield :username, String, :required => true, :validations => {matches_regexp: /^[a-zA-Z]+[\w\.-]*$/}
			yield :password, String, :required => true, :hidden => true
			yield :email, String, :required => true, :extended_only => true, :validations => {is_email: true}
			yield :firstname, String, :required => true
			yield :infix, String
			yield :lastname, String, :required => true
			yield :is_admin, Boolean, :required => true, :default => false, :extended_only => true
			yield :groupids, Array, :default => [], :hidden => true
			yield :state, String, :default => :active
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

		def has_object_right?(orig_right, object_userids, object_groupids, object_right)
			if self.administrator?
				result = true
			elsif (self.id.nil?) || (self.id == '')
				result = ((object_right & orig_right) == orig_right)
			else
				result = false
				users_right = (orig_right << 4)
				group_right = (orig_right << 8)
				owner_right = (orig_right << 12)
				result = ((object_right & users_right) == users_right) unless result
				result = (((self.userids & object_userids).length > 0) && ((object_right & owner_right) == owner_right)) unless result
				result = (((self.groupids & object_groupids).length > 0) && ((object_right & group_right) == group_right)) unless result
			end
			return result
		end

		# noinspection RubyUnusedLocalVariable
		# TODO: implementation
		def has_global_right?(mod_name, right_name)
			return self.administrator?
		end

		def user_has_right?(right, user = nil)
			user ||= API.current_user
			if user.administrator?
				return true
			elsif right == RIGHT_READ
				return (self.id == user.id) || (user.has_global_right?(:users, :show_users))
			else
				return (self.id == user.id) || (user.has_global_right?(:users, :maintain_users))
			end
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
			@fields[:cookie_tokens][:value].delete_if { | ts, _ | ts < old_timestamp }

			# Purge oldest as long as the set contains more than 50 tokens
			purge_count = @fields[:cookie_tokens][:value].length - 50
			while purge_count > 0
				@fields[:cookie_tokens][:value].shift
				purge_count -= 1
			end
			self.save_to_db
			return new_token
		end

		def to_a(compact = false)
			result = super
			result[:fullname] = (result[:firstname].to_s + ' ' + result[:infix].to_s).strip + ' ' + result[:lastname].to_s
			if !self.id.nil?
				#TODO: create avatar support. If ready implement:
				#if (has_avatar)
				#else
				avatar = 'http://www.gravatar.com/avatar/' + Digest::MD5.hexdigest(self.email.to_s) + '?d=mm'
				#end
				result[:avatar] = avatar
				result[:may_update] = (API.current_user.administrator?) || (API.current_user.id == self.id) if (!compact)
			else
				result[:may_update] = false
			end
			result[:groups_url] = API.api_url + "users/#{self.id}/groups"
			return result
		end

		# Resets the password and sends it to the know email address
		def reset_password
			#new_password =
			#new_digest = "#{this.username}:#{new_password}:#{realm}"
		end

	end


	class Users < DbObjects

		def initialize(where = {}, options = {})
			super('users', User, where, options)
		end

		def get_rights_where(user = nil)
			user ||= API.current_user
			@options[:ignore_rights] = false unless @options.include?(:ignore_rights)
			if (!@options[:ignore_rights]) && (!user.nil?) && (!user.has_global_right?(:users, :show_users))
				#TODO: implement state and set active to current users
				result = {_id: user.id} #{'$and' => [{state: 'active'}, {_id: user.id}]}
			else
				result = {} #{state: 'active'}
			end
			return result
		end

	end


end