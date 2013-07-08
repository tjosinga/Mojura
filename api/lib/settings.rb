require 'api/lib/stringconvertor'

module MojuraAPI

	module Settings
		extend self

		private

		@settings = nil
		@collection = nil

		def load_file_settings
			return if !@settings.nil? && @settings.include?(:file)
			@settings ||= {}
			@settings[:file] = YAML.load_file('project_settings.yaml')
			@settings[:file].symbolize_keys!
			@settings[:file][:private] ||= {}
			@settings[:file][:protected] ||= {}
			@settings[:file][:public] ||= {}
		end

		def load_db_settings
			return if !@settings.nil? && (@settings.include?(:db) || !MongoDb.connected?)
			@collection ||= MongoDb.collection('single_hashes')
			@settings ||= {}
			@settings[:db] = @collection.find({identifier: 'system_settings'}).to_a[0]['hash'] rescue {protected: {}, public: {}}
			#STDOUT << @collection.find({identifier: 'system_settings'}).to_a[0]['hash']
			@settings[:db].symbolize_keys!
			@settings[:db][:protected] ||= {}
			@settings[:db][:public] ||= {}
		end

		def save_db_settings
			data = {identifier: 'system_settings', type: 'settings', hash: @settings[:db]}
			@collection.update({identifier: 'system_settings'}, data, {upsert: true})
		end

		def exists?(source, level, category, key)
			@settings.include?(source) &&
				@settings[source].include?(level) &&
				@settings[source][level].include?(category) &&
				@settings[source][level][category].include?(key)
		end

		def value(source, level, category, key)
			@settings[source][level][category][key]
		end

		def get(key, category = :core, scopes = [:private, :protected, :public])
			load_file_settings
			load_db_settings
			category = category.to_sym rescue :core
			key = key.to_sym
			if scopes.include?(:private) && exists?(:file, :private, category, key)
				return @settings[:file][:private][category.to_sym][key.to_sym]
			elsif scopes.include?(:protected) && exists?(:db, :protected, category, key)
				return @settings[:db][:protected][category.to_sym][key.to_sym]
			elsif scopes.include?(:public) && exists?(:db, :public, category, key)
				return @settings[:db][:public][category.to_sym][key.to_sym]
			elsif scopes.include?(:protected) && exists?(:file, :protected, category, key)
				return @settings[:file][:protected][category.to_sym][key.to_sym]
			elsif scopes.include?(:public) && exists?(:file, :public, category, key)
				return @settings[:file][:public][category.to_sym][key.to_sym]
			else
				return nil
			end
		end

		def locate_setting(key, category = :core)
			return {type: :file, level: :private} if exists?(:file, :private, category, key)
			return {type: :file, level: :protected} if exists?(:file, :protected, category, key)
			return {type: :file, level: :public} if exists?(:file, :public, category, key)
			return {type: :db, level: :protected} if exists?(:db, :protected, category, key)
			return {type: :db, level: :public} if exists?(:db, :public, category, key)
			return nil
		end

		public

		def all(scopes = [:private, :protected, :public], include_level = true, filter = nil)
			load_file_settings
			load_db_settings
			result = {}
			filter = filter.to_sym unless filter.nil?
			scopes.each { |scope| result[scope.to_sym] = {} if @settings[:file].include?(scope.to_sym) }
			@settings.each { | _, levels|
				levels.each { |level, categories|
					categories.each { |category, keys|
						keys.each { |key, value|
							if include_level
								result[level] ||= {}
								result[level][category] ||= {}
								result[level][category][key] = value
							else
								result[category] ||= {}
								result[category][key] = value
							end
						} if (filter.nil?) || (category == filter)
					} if result.include?(level)
				}
			}
			return result
		end

		def get_s(key, category = :core, scopes = [:private, :protected, :public])
			get(key, category, scopes).to_s
		end

		def get_i(key, category = :core, scopes = [:private, :protected, :public])
			get(key, category, scopes).to_i
		end

		def get_f(key, category = :core, scopes = [:private, :protected, :public])
			get(key, category, scopes).to_f
		end

		def get_b(key, category = :core, scopes = [:private, :protected, :public])
			%w(true yes 1).include?(get(key, category, scopes).to_s.downcase)
		end

		def get_h(key, category = :core, scopes = [:private, :protected, :public])
			get(key, category, scopes) || {}
		end

		def get_a(key, category = :core, scopes = [:private, :protected, :public])
			get(key, category, scopes).to_a
		end

		def set(key, value, category = nil, level = nil, options = {})
			category = category.to_sym rescue :core
			key = key.to_sym
			load_file_settings
			load_db_settings

			location = locate_setting(key, category)
			if !location.nil?
				return if options[:ignore_if_exists].is_a?(TrueClass)
				level = location[:level]
				return NotAllowedSettingException if (level == :private)
				type = location[:type]
				old_value = @settings[type][level][category][key]
				value = StringConvertor.convert(value, old_value.class) if value.is_a?(String) && !old_value.is_a?(String)
				type = :db
			else
				level ||= :protected
				type = options[:type] || :db
			end
			@settings[type] ||= {}
			@settings[type][level] ||= {}
			@settings[type][level][category] ||= {}
			@settings[type][level][category][key] = value
			save_db_settings if (type == :db)
		end

		def unset(key, category = nil)
			category ||= :core
			category = category.to_sym
			key = key.to_sym
			load_file_settings
			load_db_settings
			if @settings[:db][:public].include?(category) && @settings[:db][:public][category].include?(key)
				@settings[:db][:public][category].delete(key)
			end
			if @settings[:db][:protected].include?(category) && @settings[:db][:protected][category].include?(key)
				@settings[:db][:protected][category].delete(key)
			end
			save_db_settings
		end

	end

end
