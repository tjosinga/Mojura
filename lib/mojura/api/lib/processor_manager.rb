module MojuraAPI

	# The ProcessorManager manages pre- and postprocessors. The processors can subscribe to an api resource and method,
	# and may even use filtering on input parameters.
	module ProcessorManager

		extend self;

		@subscriptions = {}

		def load_processors(mods, resource)
			mods.each { | mod |
				if File.exists?("#{resource}/#{mod}/#{mod}.processors.rb")
					require "#{resource}/#{mod}/#{mod}.processors.rb"
				end
			}
		end

		# Subscribe a processor to a certain resource and method. This is a private module method.
		def subscribe_processor(resource, method, processor, options = {})
			subscribed_types = []
			%i(preprocessor postprocessor).each { | type |
				if (processor.respond_to?("run_#{type}"))
					@subscriptions ||= {}
					@subscriptions[type] ||= {}
					@subscriptions[type][method] ||= {}
					@subscriptions[type][method][resource] ||= []
					@subscriptions[type][method][resource].push({ object: processor, options: options })
					subscribed_types.push(type);
				end
			}
			class_name = processor.class.name
			if subscribed_types.empty?
				API.log.warn("Processor #{class_name} should at least contain method run_preprocessor or run_postprocessor.")
			else
				API.log.info("Subscribe processor #{class_name} to '#{resource}' as " + subscribed_types.join(' and '))
			end
		end

		# Runs the preprocessors which should be run, based on the resource and the method.
		def run_preprocessors(resource, method, input)
			processors = get_processors(:preprocessor, resource, method, input)
			processors.each { | processor |
				options = { resource: resource, method: method }
				if (!processor[:options][:async].is_a?(FalseClass))
					Thread.new(Thread.current[:mojura]) { | thread_data |
						Thread.current[:mojura] = thread_data
						processor[:object].run_preprocessor(input, options)
					}
				else
					processor[:object].run_preprocessor(input, options)
				end
			}
		end

		# Runs the postprocessors which should be run, based on the resource and the method.
		def run_postprocessors(resource, method, input, output)
			processors = get_processors(:postprocessor, resource, method, input)
			processors.each { | processor |
				options = { resource: resource, method: method, processor_options: processor[:options] }
				if (!processor[:options][:async].is_a?(FalseClass))
					Thread.new(Thread.current[:mojura]) { | thread_data |
						Thread.current[:mojura] = thread_data
						processor[:object].run_postprocessor(input, output, options)
					}
				else
					processor[:object].run_postprocessor(input, output, options)
				end
			}
		end

		# Returns all processors which should be run, based on the resource and the method.
		def get_processors(type, resource, method, input)
			return [] unless @subscriptions.include?(type) &&
			                 @subscriptions[type].include?(method)
			result = []
			@subscriptions[type][method].each { | subscribed_resource, processors |
				if resource.match(/^#{subscribed_resource}$/)
					processors.each { | processor |
						input_filter = processor[:options][:input_filter] || {}
						result.push(processor) if (input_filter.size == 0) || (input_filter.all? { | k, v | input[k] == v })
					}
				end
			}
			return result
		end

	end

end