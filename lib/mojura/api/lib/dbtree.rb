#noinspection RubyResolve
require 'cgi'
require 'api/lib/mongodb'

module MojuraAPI

	# Singleton module for the single db collection containing all trees
	module DbTreeCollection
		extend self

		def collection
			@collection ||= MongoDb.collection('single_hashes')
		end
	end

	class DbTree

		@tree_collection
		@data_collection
		@cache_fields
		@tree
		@use_rights
		@object_url

		def initialize(db_col_name, use_rights = true, cache_fields = [:title], object_url = '', parent_field = :parentid, order_field = :orderid)
			@tree_collection = DbTreeCollection.collection
			@data_collection = MongoDb.collection(db_col_name.to_s)
			@db_col_name = db_col_name
			@parent_field = parent_field
			@order_field = order_field
			@cache_fields = cache_fields
			@cache_fields.push(:api_url)
			@use_rights = use_rights
			@object_url = object_url
			@tree = nil
			@id = nil
		end

		def to_a(depth = 100)
			self.load_from_db if @tree.nil?
			return self.compact_clone(@tree, depth)
		end

		def refresh
			# Refreshing could be improved by performing a partial refresh
			@tree = self.objects_to_tree
			self.save_to_db
			return self
		end

		def nodes_of_path(path = '', current_nodes = nil, check_field = :title)
			self.load_from_db if @tree.nil?
			if path.is_a?(String)
				path = path.gsub(/^\//, '').split('/')
				path.map! { |v| CGI::unescape(v) }
			end
			return [] if (path.empty?)
			current_nodes ||= @tree
			title = path.shift
			index = current_nodes.index { |data| data[check_field] == title }
			if index.nil?
				raise UnknownObjectException.new(title)
			else
				result = self.nodes_of_path(path, current_nodes[index][:children], check_field)
				result ||= []
				node = current_nodes[index].clone
				node.symbolize_keys!
				node.delete(:children)
				if @use_rights
					node[:rights] ||= {}
					node[:rights][:allowed] = self.allowed_info_of_item(node[:rights])
				end
				result.unshift(node)
			end
			return result
		end

		def parents_of_node(id, node = nil)
			return nil if (id.nil?)
			self.refresh
			self.load_from_db if @tree.nil?
			result = nil
			subnodes = (node.nil?) ? @tree : node[:children]
			if !subnodes.nil?
				subnodes.each { |subnode|
					subnode.symbolize_keys!
					if result.nil?
						result = self.parents_of_node(id, subnode) if (subnode[:id] != id)
						if (!node.nil?) && ((subnode[:id] == id) || (!result.nil?))
							copy = node.clone
							copy.delete(:children)
							if @use_rights
								copy[:rights] ||= {}
								copy[:rights][:allowed] = self.allowed_info_of_item(node[:rights])
							end
							result ||= []
							result.unshift(copy)
						end
					end
				}
			end
			return result
		end

		protected

		def objects_to_tree(parentid = nil)
			result = []
			data = @data_collection.find({parentid: parentid}).sort(@order_field).to_a
			data.each { |object|
				info = {id: object['_id'].to_s}
				@cache_fields.each { |field|
					info[field] = object[field.to_s]
				}
				info[:api_url] = @object_url + '/' + info[:id] if (@object_url != '')
				if @use_rights
					info[:rights] = {userids: object[:userids.to_s],
					                 groupids: object[:groupids.to_s],
					                 rights: object[:rights.to_s]}
				end
				self.on_object_to_tree!(object, info)
				children = self.objects_to_tree(object['_id'])
				info[:children] = children if !children.empty?
				result.push(info)
			}
			return result
		end

		#noinspection RubyUnusedLocalVariable,RubyUnusedLocalVariable
		def on_object_to_tree!(object, info)
			#dummy method. Called before stored in the tree. Override to change the info
		end

		def user_has_right(orig_right, rights)
			object = AccessControlObject.new(:pages, :Page, rights[:rights], rights[:userids], rights[:groupids])
			return AccessControl.has_rights?(orig_right, object)
		end

		def allowed_info_of_item(rights)
			{custom: self.user_has_right(RIGHT_CUSTOM, rights),
			 read: self.user_has_right(RIGHT_READ, rights),
			 update: self.user_has_right(RIGHT_UPDATE, rights),
			 delete: self.user_has_right(RIGHT_DELETE, rights)}
		end

		def compact_clone(src, depth = 0)
			result = []
			src.each { |src_info|
				allowed = self.allowed_info_of_item(src_info[:rights])
				if ((!@use_rights) || (allowed[:read])) && (on_compact(src_info))
					dest_info = {id: src_info[:id]}
					@cache_fields.each { |field|
						str = field.to_s
						value = src_info[field]
						value = API.api_url + value if (str.end_with?('_url')) && (!str.start_with?('www.')) && (!str.match('://'))
						dest_info[field] = value
					}
					if @use_rights
						dest_info[:rights] = {userid: src_info[:rights][:userid],
						                      groupid: src_info[:rights][:groupid],
						                      rights: src_info[:rights][:rights],
						                      allowed: allowed}
					end
					if (src_info.has_key?(:children)) && (depth > 0)
						dest_info[:children] = compact_clone(src_info[:children], depth - 1)
					end
					result.push(dest_info)
				end
			}
			return result
		end

		#noinspection RubyUnusedLocalVariable
		def on_compact(src_info)
			return true
		end

		def load_from_db
			data = @tree_collection.find_one({identifier: @db_col_name.to_s})
			if !data.nil?
				@id = data['_id']
				@tree = data['hash']
				@tree.symbolize_keys!
			else
				@id = nil
				@tree = []
			end
		end

		def save_to_db
			data = @tree
			data.stringify_keys!
			@tree_collection.remove({identifier: @db_col_name.to_s})
			@tree_collection.insert({identifier: @db_col_name.to_s, type: 'db_tree', hash: data})
		end

	end

end