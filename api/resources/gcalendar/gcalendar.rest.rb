require 'google/api_client'

module MojuraAPI

	class GCalendarResource < RestResource

		def name
			'Google Calendar'
		end

		def description
			'Resource for Google Calendar'
		end

		def get_calendar_api
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
			if @client.authorization.access_token.empty
				raise HTTPException.new('The GCalendar API has not yet been authorized by Google API')
			end
			calendar_api = @client.discovered_api('calendar', 'v3')
		end

		def all(params)


			result = @client.execute(
				api_method: calendar_api.calendar_list.list,
				parameters: {},
			)
			today = Date.today
			tomorrow = Date.today.next_day - 0.00001
			show_primary = Settings.get_b(:show_primary, :gcalendar, true)

			batch = Google::APIClient::BatchRequest.new
			events = []
			result.data.items.each { | cal_data |
				if !cal_data.primary || show_primary
					STDOUT << JSON.pretty_generate(cal_data) + "\n"
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
				end
			}
			@client.execute(batch)
			events.sort! { | a, b |
				if a[:time] != b[:time]
					a[:time] <=> b[:time]
				elsif a[:calendar] != b[:calendar]
					a[:calendar] <=> b[:calendar]
				else
					a[:summary] <=> b[:summary]
				end
			}
			return events
		end

		def all_conditions
			{
				description: 'Returns all Google Calendar for specified account.',
				attributes: { }
			}
		end



	end

	API.register_resource(GCalendarResource.new('gcalendar', '', '[category]/[key]'))

end