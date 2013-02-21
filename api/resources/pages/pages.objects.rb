require 'api/lib/dbobjects'
require 'api/lib/dbtree'

module MojuraAPI

  module PageTemplates
    extend self

    def templates
      load_templates if @templates.nil?
      return @templates
    end

    def load_templates
      if @templates.nil?
        @templates = {}
        path = 'api/resources/pages/templates/'
        Dir.foreach(path) { |col_count|
          if (col_count != '.') && (col_count != '..') && (File.directory?(path + col_count))
            Dir.foreach("#{path}#{col_count}/") { |name|
              if (name != '.') && (name != '..') && (File.extname(name) == '.json')
                templateid = File.basename(name, '.json')
                @templates[templateid] = {col_count: col_count.to_i, template: JSON.parse(File.read("#{path}#{col_count}/#{name}"))}
                @templates[templateid][:template].symbolize_keys!
              end
            }
          end
        }
        @templates = [@templates.sort]
      end
      return @templates
    end

    def get_templates(col_count_filter = 0)
      load_templates if (@templates.nil?)
      result = []
      @templates.each { |view_id, data|
        result.push({templateid: view_id,
                     col_count: data[:col_count],
                     api_url: API.api_url + "pages/template/#{view_id}",
                    }) if (col_count_filter == 0) || (col_count_filter == data[:col_count])
      }
      return result
    end

    def get_template(templateid)
      load_templates if (@templates.nil?)
      return {
          templateid: templateid,
          col_count: @templates[templateid][:col_count],
          template: @templates[templateid][:template],
      }
    end

  end

  class Page < DbObject

    include DbObjectTags
    include DbObjectVotes
    include DbObjectRights
    include DbObjectOrderId

    @templates = nil

    def initialize(id = nil)
      super('pages', id, {tree: PageTree})
     	Page.load_templates
    end

    def load_fields
    	yield :parentid,		BSON::ObjectId, :required => false
      yield :title,				String,  				:required => true, :default => ''
      yield :in_menu,			Boolean,  			:required => false, :default => true
      yield :menu_title,	String,  				:required => false, :default => ''
      yield :views,				Array,					:required => false
    end

    def load_from_db
    	super
   		@fields[:views][:value].symbolize_keys! if @fields[:views][:value].is_a?(Array)
    end

    def new_view(options = {})
    	{
          view: (options[:view] || ''),
          col_span: (options[:col_span] || 12),
          col_offset: (options[:col_offset] || 0),
          row_offset: (options[:row_offset] || 0),
          content: (options[:content] || ''),
          content_markup: (options[:content_markup] || 'ubb'),
          settings: (options[:settings] || {}),
          subviews: (options[:subviews] || [])
    	}
    end

    def apply_template(view, template)
    	template.each { | k, v |
    		if k == :subviews
    			v.each { | subtemplate |
    				subview = self.new_view
    				self.apply_template(subview, subtemplate)
    				view[:subviews].push(subview)
    			}
    		else
    			view[k] = v
    		end
    	}
    end

    def new_view_from_template(templateid)
    	result = self.new_view
    	self.apply_template(result, Page.get_template(templateid)[:template])
    	STDOUT << "Final view\n\n#{result.to_s}\n\n"
    	return result
    end

    def add_view(parentid, params)
    	@fields[:views][:changed] = true
    	parentid ||= ''
    	parent = self.get_view(parentid)
    	view = (params[:template].nil?) ? self.new_view(params) : self.new_view_from_template(params[:template])
    	index = params[:index]
    	if (!index.nil?) && (index.to_i < parent[:subviews].size)
    		view[:index] = index.to_i
    		parent[:subviews].insert(index.to_i, view)
			else
	    	view[:index] = parent[:subviews].size
	    	parent[:subviews].push(view)
	    end
    	return view
		end

		def update_view(viewid, params)
    	@fields[:views][:changed] = true
    	viewid ||= ''
    	view = self.get_view(viewid)
    	template = self.new_view()
    	params.each { | k, v | view[k] = v if (template.include?(k)) }

    	if params.include?(:settings)
	    	params[:settings].each { | k, v |
	    		if v.nil? || v.empty?
	    			view[:settings].delete(k)
	    		else
						view[:settings][k] = v
					end
	    	}
	    end

    	# Moving a view is done by deleting and re-inserting
    	if (params.include?(:parentid)) || (params.include?(:index))
		   	ids = viewid.split(',')
	  		cur_index = ids.pop.to_i
	  		cur_path = ids.join(',')
	  		parent = self.get_view(cur_path)
    		parent[:subviews].delete_at(cur_index)
    		if params.include?(:index)
	    		view[:index] = params[:index].to_i
  	  		view[:index] -= 1 if (view[:index] >= cur_index)
  	  	end
    		self.add_view(params[:parentid], view)
    	end
    	return view
		end

		def delete_view(viewid)
    	@fields[:views][:changed] = true
	   	ids = viewid.split(',')
  		index = ids.pop.to_i
  		path = ids.join(',')
  		subviews = (path.empty?) ? self.views : self.get_view(path)[:subviews]
  		subviews.delete_at(index)
		end

		def get_view(indexes = '', views = nil, orig_indexes = '')
			views = self.views if (views.nil?)
			if indexes.is_a?(String)
				return {subviews: views} if (indexes.empty?)
				orig_indexes = indexes
				indexes = indexes.to_s.gsub(',,', ',').split(',')
			end
			raise UnknownPageViewIdException.new(orig_indexes) if (indexes.size == 0)
			index = indexes.shift.to_i
			if (index < 0) || (index >= views.size)
				raise UnknownPageViewIdException.new(orig_indexes)
			elsif indexes.size == 0
				return views[index]
			else
				return self.get_view(indexes, views[index][:subviews], orig_indexes)
			end
		end

		def to_a
			result = super
			result[:views] = self.views_to_a(result[:views])
			return result
		end

		def view_to_a(view, index = 0, path = '')
			content = view[:content]
			markup = view[:content_markup]
			view = Marshal.load(Marshal.dump(view))
			view.delete(:content_markup)
			viewid = (path.to_s.empty?) ? index : "#{path},#{index}"
			view[:viewid] = viewid
			view[:path] = path
			view[:index] = index.to_i
			view[:view_url] = API.api_url + "pages/#{self.id}/view/#{viewid}"
			view[:content] = RichText.new(content, markup).to_parsed_a
			view[:subviews] = self.views_to_a(view[:subviews], viewid) if (!view[:subviews].nil?)
			return view
		end

		def views_to_a(views = nil, indexes = '')
			views = Marshal.load(Marshal.dump(self.views)) if (views.nil?)
			index = -1
			views.map! { | view |
				index += 1
				self.view_to_a(view, index, indexes)
			}
			return views
		end

  end


  class Pages < DbObjects

    def initialize(where = {}, options = {})
      options[:sort] = {orderid: 1} if (!options.include?(:sort))
      super('pages', Page, where, options)
    end

  end


  class PageTree < DbTree

  	attr_reader :menu_only

  	def initialize(menu_only = false)
  		@menu_only = menu_only
  		super('pages', true, [:title, :in_menu], 'pages')
  	end

  	def on_compact(src_info)
  		return (!@menu_only || (src_info[:in_menu]))
  	end

  end


  class UnknownPageViewIdException < HTTPException
    def initialize(id)
      super("The view with id '#{id}' could not be found", 502)
    end
	end



end



