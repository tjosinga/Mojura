require 'mongo'

module MojuraAPI

  module MongoDb
    extend self

    def self.connect(database = '')
      @connection = Mongo::Connection.new()
      @database = @connection.db(database.to_s)
      @collection = {}
    end

    def self.authenticate(username, password)
      raise 'Not connected to MongoDb' if @connection.nil?
      return @database.authenticate(username, password)
    end

    def self.collection(name)
      raise 'Not connected to MongoDb' if @connection.nil?
      name = name.to_s
      @collection[name] = @database.collection(name) if !@collection.include?(name)
      return @collection[name]
    end
  end
end
