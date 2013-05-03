require 'mongo'
require 'json'

module MongoTestDb
	extend self

	def init(database = 'osisoft_mojura_testset')
		@db_name = database.to_s
		@connection = Mongo::Connection.new()
		@database = @connection.db(@db_name)
		@collection = {}
		reload
	end

	def reload
		@connection.drop_database(@db_name)
		@database = @connection.db(@db_name)
		Dir.foreach('../test/testset/') { |name|
			if name.end_with?('.json')
				coll_name = name[0..-6]
#				begin
#					text = File.read("../test/testset/#{name}")
#					raise Exception("File #{name} is empty") if text.empty?
#					json = JSON::parse(text)
#					json.each { |obj_json|
#						#@collection.insert(obj_json);
#					}

#				rescue
#				end
			end
		}
	end

	def clean

	end

end

MongoTestDb.init
