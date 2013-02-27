require 'strscan'
require 'json'
require 'api/lib/exceptions'
require 'api/lib/datatypes'

module MojuraAPI

	module FilterParser

		# Convert module into Singleton
		extend self

		@total_string = ''
		@scanner = ''
		@currentkey = ''
		@processedkey = false
		@expected = {}

		def parse(str, expected = {})\
      # STDOUT << "function: parse \"#{str}\"\n"
			return nil if (str == '' || str == nil)
			@total_string = str
			@expected = expected
			@scanner = StringScanner.new(@total_string)
			return self.get_exp_list
		end

		def get_exp_list
			# STDOUT << "function: get_exp_list\n"
			and_or_mode = ''
			result = []
			i = 0
			until @scanner.eos?
				if @scanner.scan(/\(/).nil?
					result << self.get_exp_list
				elsif !@scanner.scan(/\)/).nil?
					break
				elsif !@scanner.match?(/\w+/).nil?
					result << self.get_exp
				else
					result << nil
				end

				# STDOUT << "function: get_exp_list => " + result.count.to_s + " - " + result.to_s + "\n"

				if and_or_mode == ''
					and_or_mode = @scanner.scan(/[,\|]/)
				else
					token = @scanner.scan(/[,\|]/)
					raise InvalidFilterException.new(@scanner.pointer(), 'Invalid combination of | and ,') if (!token.nil?) && (token != and_or_mode)
				end
				raise InvalidFilterException.new(@scanner.pointer(), 'Infinite loop in get_exp_list. Next character is ' + @scanner.scan(/./)) if (i > @total_string.length)
				i = i.next
			end

			if and_or_mode == '|'
				return {'$or' => result}
			elsif result.count > 1
				return {'$and' => result}
			elsif result.is_a?(Array)
				return result[0]
			else
				return result
			end

		end

		def get_exp
			# STDOUT << "function: get_exp\n"
			@currentkey = @scanner.scan(/\w+/)
			@processedkey = false
			# STDOUT << "Found key: #{@currentkey}\n"
			@scanner.scan(/:/)
			value = self.get_value_or_list
			if value.is_a?(Array) && (value.count > 1)
				result = []
				value.each { |v| result.push({@currentkey => v}) }
			elsif !@processedkey
				result = {@currentkey => value}
				# STDOUT << "TESTTEST" + result.to_s + "\n"
			else
				# STDOUT << "TESTTESTTEST\n"
				result = value
			end

			return result
		end

		def get_value_or_list(allow_and_or_operator = true)
			# STDOUT << "function: get_value_or_list\n"
			if @scanner.scan(/\(/)
				result = self.get_value_list(allow_and_or_operator)
				@scanner.skip(/\)/)
				return result
			else
				return self.get_value
			end
		end

		def get_value
			# STDOUT << "function: get_value\n"
			if @scanner.scan(/\{/)
				result = self.get_operation
				@scanner.skip(/\}/)
				return result
			else
				token = @scanner.scan(/((\w+)|('.+')|(".+"))/)
				token = token.strip_quotes if (!token.nil?)
				# STDOUT << "Found value: #{token}\n"
				# type checking should be implemented here.
				return token
			end
		end

		def get_value_list(allow_and_or_operator = true)
			# STDOUT << "function: get_value_list\n"
			and_or_mode = ''
			values = []
			i = 0
			while @scanner.scan(/\)/).nil?
				values << self.get_value
				if and_or_mode == ''
					and_or_mode = @scanner.scan(/[,\|]/)
				else
					token = @scanner.scan(/[,\|]/)
					raise InvalidFilterException.new(@scanner.pointer(), 'Invalid combination of | and ,') if (!token.nil?) && (token != and_or_mode)
				end
				raise InvalidFilterException.new(@scanner.pointer(), 'Infinite loop in get_value_list') if (i > @total_string.length)
				i = i.next
			end
			if (allow_and_or_operator) && (and_or_mode != '')
				result = []
				@processedkey = true
				values.each { |v| result.push({@currentkey => v}) }
				if and_or_mode == '|'
					return {'$or' => result}
				else
					return {'$and' => result}
				end
			else
				return values
			end
		end

		def get_operation
			# STDOUT << "function: get_operation\n"
			operator = self.get_operator
			@scanner.scan(/:/)
			value = self.get_value_or_list(false)
			return {operator => value}
		end

		def get_operator
			# STDOUT << "function: get_operator\n"
			accepts = %w(lt lte gt gte all ne in nin nor size type)
			operator = @scanner.scan(/\w+/)
			unless accepts.include? operator
				raise InvalidFilterException.new(@scanner.pointer(), "Invalid operator #{operator}")
			end
			return '$' + operator
		end

	end

end