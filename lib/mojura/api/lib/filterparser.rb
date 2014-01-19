require 'strscan'
require 'json'
require 'api/lib/exceptions'
require 'api/lib/datatypes'
require 'api/lib/stringconvertor'

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
			return nil if (str == '' || str == nil)
			@total_string = str
			@expected = expected
			@scanner = StringScanner.new(@total_string)
			return self.get_exp_list
		end

		def get_exp_list
			and_or_mode = ''
			result = []
			i = 0
			while !@scanner.eos?
				if !@scanner.scan(/\(/).nil?
					result << self.get_exp_list
				elsif !@scanner.scan(/\)/).nil?
					break
				elsif !@scanner.match?(/\w+/).nil?
					result << self.get_exp
				else
					result << nil
				end

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
			@currentkey = @scanner.scan(/\w+/)
			@processedkey = false
			@scanner.scan(/:/)
			value = self.get_value_or_list
			if value.is_a?(Array) && (value.count > 1)
				result = []
				value.each { |v| result.push({@currentkey => v}) }
			elsif !@processedkey
				result = {@currentkey => value}
			else
				result = value
			end

			return result
		end

		def get_value_or_list(allow_and_or_operator = true)
			if @scanner.scan(/\(/)
				result = self.get_value_list(allow_and_or_operator)
				@scanner.skip(/\)/)
				return result
			else
				return self.get_value
			end
		end

		def get_value
			if @scanner.scan(/\{/)
				result = self.get_operation
				@scanner.skip(/\}/)
				return result
			else
				token = @scanner.scan(/((\w+)|('.+')|(".+"))/)
				token = token.strip_quotes if (!token.nil?)
				# TODO: extra type checking should be implemented here.
				if token.match(/^(true|false)$/)
					token = StringConvertor.convert(token, :boolean)
				elsif token.match(/^\-?\d+$/)
					token = StringConvertor.convert(token, :integer)
				end
				return token
			end
		end

		def get_value_list(allow_and_or_operator = true)
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
			operator = self.get_operator
			@scanner.scan(/:/)
			value = self.get_value_or_list(false)
			return {operator => value}
		end

		def get_operator
			accepts = %w(lt lte gt gte all ne in nin nor size type)
			operator = @scanner.scan(/\w+/)
			unless accepts.include? operator
				raise InvalidFilterException.new(@scanner.pointer(), "Invalid operator #{operator}")
			end
			return '$' + operator
		end

	end

end