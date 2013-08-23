require 'mustache'

module MojuraWebApp

	class ViewWrapper < BaseView

		attr_reader :view

		def initialize(options = {})
			options ||= {}

			@view = (options[:view] || nil)
			@subview_index = 0

			options[:add_span] = true if !options.include?(:add_span)
			options[:parent_col_span] ||= 12
			options[:col_span] ||= options[:parent_col_span]
			options[:col_offset] ||= 0

			# Conversion from the original 12-col grid to the recursive 12-col grid
			options[:col_devices] ||= 'md'
			options[:col_rec] = ((12 / options[:parent_col_span]) * options[:col_span]).floor
			options[:col_rec_offset] = ((12 / options[:parent_col_span]) * options[:col_offset]).floor

			data = {}
			data[:viewid] = (options[:viewid] || '')
			data[:pageid] = WebApp.page.id
			data[:settings] = (options[:settings] || {})
			data[:subviews] = (options[:subviews] || [])
			data[:may_edit_view] = (options.include?(:may_edit_view) && options[:may_edit_view])
			data[:classes] = options[:classes] || 'view'
			data[:classes] += " #{data[:settings][:classes]}" if (data[:settings].include?(:classes))
			data[:classes] += " col-#{options[:col_devices]}-#{options[:col_rec]}" if (options[:add_span])
			data[:classes] += " col-#{options[:col_devices]}-offset-#{options[:col_rec_offset]}" if (options[:col_rec_offset].to_i > 0)
			data[:classes] += " row-offset#{options[:row_offset]}" if (options[:row_offset].to_i > 0)
			data[:classes].strip!
			options[:wrapping] = (options[:wrapping].nil?) ? 'normal' : options[:wrapping].to_s
			data[:no_wrapping] = (options[:wrapping].to_s == 'nowrap')
			data[:simple_wrapping] = (options[:wrapping].to_s == 'simple')
			data[:normal_wrapping] = (options[:wrapping].to_s == 'normal')
			data[:html] = (options[:html] || options[:content][:html] || '') rescue ''
			super(options, data)

			if data[:may_edit_view]
				data[:templates] = WebApp.api_call('pages/templates', {col_count: options[:col_span]})
				data[:templates].each { |data_item|
					data_item[:title] = Locale.str(:view_template_names, data_item[:templateid])
				}
			end
		end

		def render_view
			return nil if (@view.nil?) || (@view.empty?)

			path = "webapp/views/#{@view}/"
			if File.exists?("#{path}/style.min.css")
				WebApp.page.include_style_link("views/#{@view}/style.min.css")
			elsif File.exists?("#{path}/style.css")
				WebApp.page.include_style_link("views/#{@view}/style.css")
			end

			if File.exists?("#{path}/script.min.js")
				WebApp.page.include_script_link("views/#{@view}/script.min.js")
			elsif File.exists?("#{path}/script.js")
				WebApp.page.include_script_link("views/#{@view}/script.js")
			end

			begin
				source_file = "#{path}/view_main"
				require(source_file) if (File.exists?(source_file + '.rb'))
			rescue Exception => e
				raise CorruptViewFileException.new(@view, e.to_s)
			end

			begin
				view_class = WebApp.get_view_class(@view)
				raise UnknownViewException.new(@view) if (view_class.nil?)
				options = @data[:settings].clone
				options[:parent_col_span] = @options[:col_span]
				result = view_class.new(options).render
			rescue UnknownViewException => e
				result = e.message
			rescue Exception => e
				result = Locale.str('system', 'view_render_error')
				result += ': ' + e.message + '<br />'
				result += '<pre>' + JSON.pretty_generate(e.backtrace) + '</pre>'
			end
			return result
		end

		def render_subview
			options = (data[:subviews][@subview_index] || {})
			options[:may_edit_view] = @options[:may_edit_view]
			options[:parent_col_span] = @options[:col_span]
			result = WebApp.render_view(options)
			@subview_index += 1
			return result
		end

		def has_html
			(!data[:html].empty?)
		end

		def has_data
			(!@view.empty?)
		end

		def has_subviews
			(data[:subviews].size > 0)
		end

	end

end