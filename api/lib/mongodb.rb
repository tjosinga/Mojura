require 'mongo'

module MojuraAPI

  module MongoDb

    @@connection = nil
    @@database = nil
    @@collection = nil


    def self.connect(database = '')
      @@connection = Mongo::Connection.new()
      @@database = @@connection.db(database.to_s)
      @@collection = {}
    end

    def self.authenticate(username, password)
      raise 'Not connected to MongoDb' if @@connection.nil?
      return @@database.authenticate(username, password)
    end

    def self.database
      return @@database
    end

    def self.collection(name)
    	name = name.to_s
      raise 'Not connected to MongoDb' if @@connection.nil?
      @@collection[name] = @@database.collection(name) if !@@collection.include?(name)
      return @@collection[name]
    end
  end
end
