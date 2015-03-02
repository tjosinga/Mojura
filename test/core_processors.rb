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

		def test_run_postprocessors
			p1 = PostProcessorMocker.new
			p2 = PostProcessorMocker.new

			ProcessorManager.subscribe_processor('resource1', :get, p1)
			ProcessorManager.subscribe_processor('resource2', :get, p1)
			ProcessorManager.subscribe_processor('resource3', :get, p1, input_filter: {test1: 'Hello'})

			ProcessorManager.subscribe_processor('resource2', :get, p2)
			ProcessorManager.subscribe_processor('resource3', :get, p2, input_filter: {test2: 'Hello'})

			ProcessorManager.subscribe_processor('resource4/\w+', :get, p2)
			ProcessorManager.subscribe_processor('resource5/\w+/subresource', :get, p2)

			ProcessorManager.subscribe_processor('resource6', :get, p2, output_filter: {test7: 10})
			ProcessorManager.subscribe_processor('resource7', :get, p2, output_filter: {test7: 12})


			input1 = { test1: 'Hello', test2: 'World' }
			input2 = { test5: 'Hello' }

			output1 = { test3: 'Lorem', test4: 'Ipsum' }
			output2 = { test6: true }
			output3 = { test7: 12 }

			ProcessorManager.run_postprocessors('resource1', :get, input1, output1)
			ProcessorManager.run_postprocessors('resource1', :post, input2, output2)
			sleep(0.05) # Wait for async to finish
			assert_equal(input1, p1.last_input);
			assert_equal(output1, p1.last_output);
			assert_equal({resource: 'resource1', method: :get, processor_options: {}}, p1.last_options)

			ProcessorManager.run_postprocessors('resource2', :get, input2, output2)
			sleep(0.05) # Wait for async to finish
			assert_equal(input2, p1.last_input);
			assert_equal(output2, p1.last_output);
			assert_equal({resource: 'resource2', method: :get, processor_options: {}}, p1.last_options)

			assert_equal(input2, p2.last_input);
			assert_equal(output2, p2.last_output);
			assert_equal({resource: 'resource2', method: :get, processor_options: {}}, p2.last_options)

			ProcessorManager.run_postprocessors('resource3', :get, input1, output3)
			sleep(0.05) # Wait for async to finish
			assert_equal(output3, p1.last_output);
			assert_not_equal(output3, p2.last_output);

			ProcessorManager.run_postprocessors('resource3', :get, input1, output3)
			sleep(0.05) # Wait for async to finish
			assert_equal(output3, p1.last_output);
			assert_not_equal(output3, p2.last_output);

			ProcessorManager.run_postprocessors('resource4/variableid', :get, input1, output1)
			sleep(0.05) # Wait for async to finish
			assert_not_equal(output1, p1.last_output);
			assert_equal(output1, p2.last_output);

			ProcessorManager.run_postprocessors('resource5/variable_id/subresource', :get, input1, output2)
			sleep(0.05) # Wait for async to finish
			assert_not_equal(output2, p1.last_output);
			assert_equal(output2, p2.last_output);

			ProcessorManager.run_postprocessors('resource6', :get, {}, output3)
			sleep(0.05) # Wait for async to finish
			assert_not_equal(output3, p2.last_output);

			ProcessorManager.run_postprocessors('resource7', :get, {}, output3)
			sleep(0.05) # Wait for async to finish
			assert_equal(output3, p2.last_output);

		end

	end

end