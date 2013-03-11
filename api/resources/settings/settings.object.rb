require 'api/lib/stringconvertor'

module MojuraAPI

	module Settings
		extend self

		private

		@settings = nil

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
			@settings ||= {}
			@settings[:db] = MongoDb.collection('settings').find.to_a[0].to_hash rescue {protected: {}, public: {}}
			@settings[:db].symbolize_keys!
			@settings[:db][:protected] ||= {}
			@settings[:db][:public] ||= {}
		end

		def save_db_settings
			MongoDb.collection('settings').update({}, {'$set' => @settings})
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

		public

		def all(scopes = [:private, :protected, :public], include_level = true, filter = nil)
			load_file_settings
			load_db_settings
			result = {}
			filter = filter.to_sym unless filter.nil?
			scopes.each { |scope| result[scope.to_sym] = {} if @settings[:file].include?(scope.to_sym) }
			@settings.each { |source, levels|
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

		def get(key, default = nil, category = :core, scopes = [:private, :protected, :public])
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
				return default
			end
		end

		def set(key, value, category = nil, level = nil)
			level ||= :protected
			level = level.to_sym
			category ||= :core
			category = category.to_sym
			key = key.to_sym
			load_file_settings
			load_db_settings
			@settings[:db] ||= {}
			@settings[:db][level] ||= {}
			@settings[:db][level][category] ||= {}
			@settings[:db][level][category][key] = value
			save_db_settings
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
