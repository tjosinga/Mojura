module MojuraWebApp

	#noinspection RubyClassVariableUsageInspection
	class GCalendarView < BaseView

		def initialize(options = {})
			app_name = 'Mojura - ' + Settings.get_s(:view_title, :gcalendar)
			app_version = Settings.get_s(:version, :gcalendar)
			@client = Google::APIClient.new(:application_name => app_name, :application_version => app_version)
			@client.authorization.client_id = Settings.get_s(:client_id, :gcalendar)
			@client.authorization.client_secret = Settings.get_s(:client_secret, :gcalendar)
			@client.authorization.access_token = Settings.get_s(:access_token, :gcalendar)
			@client.authorization.refresh_token = Settings.get_s(:refresh_token, :gcalendar)
			@client.authorization.redirect_uri = WebApp.page.base_url + 'gcalendar'
			@client.authorization.scope = 'https://www.googleapis.com/auth/calendar.readonly'
			@client.authorization.update_token!

			process_auth_code if (!WebApp.page.request_params[:code].nil? rescue false)
			super
		end

		def has_credentials
			!@client.authorization.client_id.empty? && !@client.authorization.client_secret.empty?
		end

		def is_authenticated
			!@client.authorization.access_token.empty? && (WebApp.page.request_params[:reauth] != 'true')
		end

		def may_authorize
			WebApp.current_user.administrator?
		end

		def auth_redirect_url
			return @client.authorization.authorization_uri
		end

		def process_auth_code
			STDOUT << "Processing tokens\n"
			@client.authorization.code = WebApp.page.request_params[:code]
			@client.authorization.fetch_access_token!
			Settings.set(:access_token, @client.authorization.access_token, :gcalendar)
			Settings.set(:refresh_token, @client.authorization.refresh_token, :gcalendar)
		end

		def todays_events
			calendar_api = @client.discovered_api('calendar', 'v3')

			result = @client.execute(
				api_method: calendar_api.calendar_list.list,
				parameters: {},
			)
			today = Date.today
			tomorrow = Date.today.next_day - 0.00001

			batch = Google::APIClient::BatchRequest.new
			events = []
			result.data.items.each { | cal_data |
				command = {
					api_method: calendar_api.events.list,
					parameters: {
						'calendarId' => cal_data['id'],
						'timeMin' => today.strftime('%FT%TZ'),
						'timeMax' => tomorrow.strftime('%FT%TZ')
					}
				}
				Google::APIClient::Schema::Calendar::V3::EventDateTime.new
				batch.add(command) { | result |
					if result.data.items.size > 0
						result.data.items.each { | event_data |
							events.push({
								calendar: cal_data.summary,
								time: event_data.start['dateTime'].strftime('%H:%M'),
							  summary: event_data.summary
							})
						}
					end
				}
			}
			@client.execute(batch)
			return events
		end

	end

	WebApp.register_view('gcalendar', GCalendarView, :min_col_span => 2)

end