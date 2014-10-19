require 'json'
require 'xmlsimple'
require 'csv'
require 'api/lib/datatypes'

module Mojura

	class Formatter

		def initialize(app)
			@app = app
		end

		def call(env)
			return_type = (env['PATH_INFO'][/.*\.([\w]*)$/, 1] || '').downcase
			env['PATH_INFO'] = env['PATH_INFO'][0..(-1 * (return_type.length + 2))] if (return_type != '')

			status, headers, body = @app.call(env)

			if !headers.include?('Content-Type') || headers['Content-Type'] == ''
				return_type = headers['return_type'] if headers.include?('return_type')
				body = body[0]
				req = Rack::Request.new(env)
				return_type = 'jsonp' if ((!req.params['callback'].nil?) && (req.params['callback'] != ''))

				return_type = ((env['is_api_call']) ? 'json' : 'html') if (return_type == '')

				body_str, ctype = case return_type
					                  when 'json' then
						                  [self.to_json(body), 'application/json']
					                  when 'jsonp' then
						                  [self.to_jsonp(body, env), 'text/javascript']
					                  when 'xml' then
						                  [self.to_xml(body), 'text/xml']
					                  when 'csv' then
						                  [self.to_csv(body, env), 'text/csv']
					                  when 'ics' then
						                  [self.to_ics(body), 'text/ics']
					                  when 'vcard' then
						                  [self.to_vcard(body), 'text/vcard']
					                  when 'txt' then
						                  [self.to_txt(body), 'text/plain']
					                  when 'html' then
						                  [self.to_html(body), 'text/html']
					                  else
						                  [self.to_json(body), 'application/json']
				                  end
				headers['Content-Type'] = ctype if !headers.include?('Content-Type')
				body = [body_str]
			end
			return [status, headers, body]
		end

		def to_json(body)
			return body.to_json
		end

		def to_jsonp(body, env)
			req = Rack::Request.new(env)
			return "#{req.params['callback']}(#{body.to_json})"
		end

		def to_xml(body)
			options = {
				NoAttr: true,
				XmlDeclaration: true,
				GroupTags: {children: 'child', siblings: 'sibling', items: 'item'},
				anonymousTag: 'item',
				rootname: 'mojura'
			}
			return XmlSimple.xml_out(body.remove_nil_values!, options)
		end

		def to_csv(body, env)
			req = Rack::Request.new(env)
			array_path = req.params['array_path']
			if (!array_path.nil? && !array_path.empty?)
				array_path = array_path.split('.')
				array_path.each { | field | body = body[field.to_sym] rescue nil }
			end
			body = [body] if body.is_a? Hash
			return '' if !body[0].is_a? Hash

			headers = body[0].keys
			subfields = req.params['subfields'].to_s.split(',')
			subfields.each { | subfield_path |
				subdata = body[0]
				path = subfield_path.split('.')
				path.each { | p | subdata = subdata[p.to_sym] rescue nil }
				subdata = subdata[0] if subdata.is_a?(Array)
				subdata.keys.each { | k | headers << subfield_path.to_s + '.' + k.to_s } if subdata.is_a?(Hash)
			}

			options = {
				headers: headers,
				col_sep: req.params['col_sep'] || ',',
				write_headers: true
			}

			subfields = req.params['subfields'].to_s.split(',')

			return CSV.generate(options) { | csv |
				body.each { | row |
					data = []
					row.each { | k, v |
						v = v.values.join(', ') if v.is_a?(Hash)
						v = v.join(', ') if v.is_a?(Array)
						data << v.to_s unless subfields.include?(k)
					}
					subfields = req.params['subfields'].to_s.split(',')
					subfields.each { | subfield_path |
						subdata = body[0]
						path = subfield_path.split('.')
						path.each { | p | subdata = subdata[p.to_sym] rescue nil }
						subdata = subdata[0] if subdata.is_a?(Array)
						data += subdata.values if subdata.is_a?(Hash)
					}
					csv << data
				}
			}
		end

		def to_ics(body)
			body.first
			body.each
			return 'ICS files not supported yet'
		end

		#noinspection RubyUnusedLocalVariable
		def to_vcard(body)
			return 'Vcards not supported yet\n\nRaw data:\n' + body.to_s
		end

		def to_txt(body)
			return body.to_s
		end

		def to_html(body)
			return body.to_s
		end

	end
end