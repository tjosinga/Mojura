require 'api/lib/restresource'
require 'api/lib/restresource_tags'
require 'api/resources/events/events.objects'

module MojuraAPI

	class EventsResource < RestResource

		def name
			'Events'
		end

		def description
			'Resource of calendar events'
		end

		def all(params)
			params[:pagesize] ||= 50
			result = paginate(params) { |options| Events.new(params[:start], params[:end], self.filter(params), options) }
			return result
		end

		def post(params)
			Event.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			Event.new(params[:ids][0]).to_a
		end

		def put(params)
			event = Event.new(params[:ids][0])
			event.load_from_hash(params)
			return event.save_to_db.to_a
		end

		def delete(params)
			event = Event.new(params[:ids][0])
			event.delete_from_db
			return [:success => true]
		end

		def all_conditions
			result = {
				description: 'Returns a list of calendar events. Use pagination and filtering to make selections.',
				attributes: {
					start: {required: false, type: Time, description: 'The start date of the selected range, formatted in ISO8601. Default is now.'},
					end: {required: false, type: Time, description: 'The end date and time of the event, formatted in ISO8601. Default is none.'},
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def post_conditions
			result = {
				description: 'Creates a event and returns the resource.',
				attributes: {
					title: {required: true, type: String, description: 'The title of the event.'},
					category: {required: false, type: String, description: 'The category of the event.'},
					start: {required: true, type: Time, description: 'The start date and time of the event, formatted in ISO8601.'},
					duration: {required: false, type: Integer, description: 'The end date of the event.'},
					all_day: {required: false, type: Boolean, description: 'True if it is an all day event.'},
					notes: {required: false, type: RichText, description: 'The notes of the event.'},
				}
			}
			result[:attributes].merge(self.rights_conditions)
			result[:attributes].merge(self.tags_conditions)
			return result
		end

		def get_conditions
			{
				description: 'Returns an event with the specified eventid',
			}
		end

		def put_conditions
			result =
				{
					description: 'Updates an event with the given keys.',
					attributes: self.post_conditions[:attributes].each { |_, v| v[:required] = false }
				}
			return result
		end

		def delete_conditions
			{
				description: 'Deletes the event'
			}
		end

	end

	API.register_resource(EventsResource.new('events', '', '[eventid]'))
	API.register_resource(TagsResource.new('events', '[eventid]/tags', Event))

end