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

		# Subscribes a preprocessor to a certain resource and method.
		def subscribe_preprocessor(resource, method, processor, options = {})
			subscribe_processor(:preprocessor, resource, method, processor, options)
		end

		# Subscribes a postprocessor to a certain resource and method.
		def subscribe_postprocessor(resource, method, processor, options = {})
			subscribe_processor(:postprocessor, resource, method, processor, options)
		end

		# Subscribe a processor to a certain resource and method. This is a private module method.
		def subscribe_processor(type, resource, method, processor, options = {})
			unless (processor.respond_to?("run_#{type}"))
				raise "Processor #{processor.class.name} misses method run_#{type}."
			end
			API.log.info("Registering #{type} #{processor.class.name} for resource #{resource}") rescue nil
			@subscriptions ||= {}
			@subscriptions[type] ||= {}
			@subscriptions[type][method] ||= {}
			@subscriptions[type][method][resource] ||= []
			@subscriptions[type][method][resource].push({ object: processor, options: options })
		end
		private_class_method :subscribe_processor

		# Runs the preprocessors which should be run, based on the resource and the method.
		def run_preprocessors(resource, method, input)
			processors = get_processors(:preprocessor, resource, method, input)
			processors.each { | processor |
				options = { resource: resource, method: method }
				processor[:object].run_postprocessor(input, options)
			}
		end

		# Runs the postprocessors which should be run, based on the resource and the method.
		def run_postprocessors(resource, method, input, output)
			processors = get_processors(:postprocessor, resource, method, input)
			processors.each { | processor |
				options = { resource: resource, method: method, processor_options: processor[:options] }
				processor[:object].run_postprocessor(input, output, options)
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
		private_class_method :get_processors

	end

end