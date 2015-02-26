require 'digest'
require 'mail'
require 'api/lib/dbobjects'
require 'api/lib/processor_manager'

module MojuraAPI

	class SendMailPostProcessor

		def run_postprocessor(input, output, options)
			receiver = Settings.get_s('receiver_' + output[:type], :data)
			receiver = Settings.get_s(:receiver, :data) if receiver.empty?
			if receiver.empty?
				API.log.warn("There's no known receiver for data block emails. The data block is stored, but not send as e-mail")
				return false
			end

			website = Thread.current[:mojura][:env]['HTTP_HOST']

			subject = Settings.get_s('subject_' + output[:type], :data)
			subject = Settings.get_s(:subject, :data, sprintf(Locale.str(:data, :default_subject), website)) if subject.empty?

			body = Settings.get_s('body_' + output[:type], :data)
			body = Settings.get_s(:body, :data, sprintf(Locale.str(:data, :default_body), website)) if body.empty?
			body = (body + "\n\n").gsub("^\n*", '')
			if (output[:text].is_a?(Hash)) && (!output[:text][:raw].to_s.empty?)
				body += (UBBParser.strip_ubb(output[:text][:raw]) + "\n\n").gsub("^\n*", '')
			end

			output[:values].each { | k, v |
				body += "#{k}: #{v}\n"
			}

			mail = Mail.new
			mail[:from] = "#{output[:name]} <#{output[:email]}>"
			mail[:to] = receiver
			mail[:subject] = subject
			mail[:body] = body
			mail.delivery_method(:sendmail)
			mail.deliver!
		end

	end

	ProcessorManager.subscribe_postprocessor('data', :post, SendMailPostProcessor.new, input_filter: {type: 'contact'})

end