require 'api/lib/stringconvertor'

module MojuraAPI

	module Settings
		extend self

		private

		@settings = nil

		def load_file_settings
			return if !@settings.nil? && @settings.include?(:file)
			@settings        ||= {}
			@settings[:file] = YAML.load_file('project_settings.yaml')
			@settings[:file].symbolize_keys!
			@settings[:file][:private]   ||= {}
			@settings[:file][:protected] ||= {}
			@settings[:file][:public]    ||= {}
		end

		def load_db_settings
			return if !@settings.nil? && (@settings.include?(:db) || !MongoDb.connected?)
			@settings ||= {}
			@settings[:db] = MongoDb.collection('settings').find.to_a[0].to_hash rescue {protected: {}, public: {}}
			@settings[:db].symbolize_keys!
			@settings[:db][:protected] ||= {}
			@settings[:db][:public]    ||= {}
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

		def all(scopes = [:private, :protected, :public], include_level = true)
			load_file_settings
			load_db_settings
			result = {}
			scopes.each { |scope| result[scope.to_sym] = {} if @settings[:file].include?(scope.to_sym) }
			@settings.each { |source, levels|
				levels.each { |level, categories|
					categories.each { |category, keys|
						result[level][category] ||= {}
						keys.each { |key, value|
							if include_level
								result[level]                ||= {}
								result[level][category]      ||= {}
								result[level][category][key] = value
							else
								result[category]      ||= {}
								result[category][key] = value
							end
						}
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

		def set(key, value, category = :core, level = :protected)
			load_file_settings
			load_db_settings
			@settings[:db]                                            ||= {}
			@settings[:db][level.to_sym]                              ||= {}
			@settings[:db][level.to_sym][category.to_sym]             ||= {}
			@settings[:db][level.to_sym][category.to_sym][key.to_sym] = value
			save_db_settings
		end

	end

end
