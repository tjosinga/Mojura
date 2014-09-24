require 'digest'
require 'mail'
require 'api/lib/dbobjects'
require 'api/resources/groups/groups.objects'

module MojuraAPI

	class DataBlock < DbObject

		def initialize(id = nil)
			super('data', id)
		end

		def load_fields
			yield :type, String, :required => true
			yield :name, String, :required => true
			yield :email, String, :required => true, :validations => {is_email: true}
			yield :timestamp, DateTime, :required => true, :default => Time.new.iso8601
			yield :text, RichText, :required => false
			yield :values, Hash, :required => false, :default => {}
		end

		def save_to_db(send_email = true)
			result = super()
			send_as_email if send_email
			return result
		end

		def send_as_email
			receiver = Settings.get_s('receiver_' + type, :data)
			receiver = Settings.get_s(:receiver, :data) if receiver.empty?
			if receiver.empty?
				API.log.warn("There's no known receiver for data block emails. The data block is stored, but not send as e-mail")
				return false # break
			end

			website = Thread.current[:mojura][:env]['HTTP_HOST']

			subject = Settings.get_s('subject_' + type, :data)
			subject = Settings.get_s(:subject, :data, sprintf(Locale.str(:data, :default_subject), website)) if subject.empty?

			body = Settings.get_s('body_' + type, :data)
			body = Settings.get_s(:body, :data, sprintf(Locale.str(:data, :default_body), website)) if body.empty?
			body = (body + "\n\n").gsub("^\n*", '')
			body += (text + "\n\n").gsub("^\n*", '') unless text.nil?
			values.each { | k, v |
				body += "#{k}: #{v}\n"
			}

			mail = Mail.new
			mail[:from] = "#{name} <#{email}>"
			mail[:to] = receiver
			mail[:subject] = subject
			mail[:body] = body
			mail.delivery_method(:sendmail)
			mail.deliver!

			return true
		end

	end


	class DataBlocks < DbObjects

		def initialize(where = {}, options = {})
			options[:sort] ||= {timestamp: -1}
			super('data', DataBlock, where, options)
		end

	end


end



