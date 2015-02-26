$:.unshift File.join(File.dirname(__FILE__), '../lib/mojura/')
require 'test/unit'
require 'api/lib/processor_manager'

module MojuraAPI

	class PreProcessorMocker

		attr_reader :last_input, :last_options

		def run_preprocessor(input, options = {})
			@last_input = input
			@last_options = options
		end

	end

	class PostProcessorMocker

		attr_reader :last_input, :last_output, :last_options

		def run_postprocessor(input, output, options = {})
			@last_input = input
			@last_output = output
			@last_options = options
		end

	end


	class ProcessorManagerTester < Test::Unit::TestCase

		def test_bad_processor
			assert_raise(RuntimeError) {
				ProcessorManager.subscribe_preprocessor('salt', :get, PostProcessorMocker.new)
			}

			assert_raise(RuntimeError) {
				ProcessorManager.subscribe_preprocessor('salt', :get, PostProcessorMocker.new)
			}

			assert_nothing_raised {
				ProcessorManager.subscribe_preprocessor('salt', :get, PreProcessorMocker.new)
			}

			assert_nothing_raised {
				ProcessorManager.subscribe_postprocessor('salt', :get, PostProcessorMocker.new)
			}
		end

		def test_run_postprocessors
			p1 = PostProcessorMocker.new
			p2 = PostProcessorMocker.new

			ProcessorManager.subscribe_postprocessor('resource1', :get, p1)
			ProcessorManager.subscribe_postprocessor('resource2', :get, p1)
			ProcessorManager.subscribe_postprocessor('resource3', :get, p1, input_filter: {test1: 'Hello'})

			ProcessorManager.subscribe_postprocessor('resource2', :get, p2)
			ProcessorManager.subscribe_postprocessor('resource3', :get, p2, input_filter: {test2: 'Hello'})

			ProcessorManager.subscribe_postprocessor('resource4/\w+', :get, p2)
			ProcessorManager.subscribe_postprocessor('resource5/\w+/subresource', :get, p2)

			input1 = { test1: 'Hello', test2: 'World' }
			input2 = { test5: 'Hello' }

			output1 = { test3: 'Lorem', test4: 'Ipsum' }
			output2 = { test6: true }
			output3 = { test7: 12 }

			ProcessorManager.run_postprocessors('resource1', :get, input1, output1)
			ProcessorManager.run_postprocessors('resource1', :post, input2, output2)
			assert_equal(input1, p1.last_input);
			assert_equal(output1, p1.last_output);
			assert_equal({resource: 'resource1', method: :get, processor_options: {}}, p1.last_options)

			ProcessorManager.run_postprocessors('resource2', :get, input2, output2)
			assert_equal(input2, p1.last_input);
			assert_equal(output2, p1.last_output);
			assert_equal({resource: 'resource2', method: :get, processor_options: {}}, p1.last_options)

			assert_equal(input2, p2.last_input);
			assert_equal(output2, p2.last_output);
			assert_equal({resource: 'resource2', method: :get, processor_options: {}}, p2.last_options)

			ProcessorManager.run_postprocessors('resource3', :get, input1, output3)
			assert_equal(output3, p1.last_output);
			assert_not_equal(output3, p2.last_output);

			ProcessorManager.run_postprocessors('resource3', :get, input1, output3)
			assert_equal(output3, p1.last_output);
			assert_not_equal(output3, p2.last_output);

			ProcessorManager.run_postprocessors('resource4/variableid', :get, input1, output1)
			assert_not_equal(output1, p1.last_output);
			assert_equal(output1, p2.last_output);

			ProcessorManager.run_postprocessors('resource5/variable_id/subresource', :get, input1, output2)
			assert_not_equal(output2, p1.last_output);
			assert_equal(output2, p2.last_output);

		end

	end

end