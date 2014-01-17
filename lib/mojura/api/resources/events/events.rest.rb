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
			result = paginate(params) { |options| Events.new(self.filter(params), options) }
			return result
		end

		def put(params)
			Event.new.load_from_hash(params).save_to_db.to_a
		end

		def get(params)
			Event.new(params[:ids][0]).to_a
		end

		def post(params)
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
				}
			}
			result[:attributes].merge(self.filter_conditions)
			return result
		end

		def put_conditions
			result = {
				description: 'Creates a event and returns the object.',
				attributes: {
					title: {required: true, type: String, description: 'The title of the event.'},
					category: {required: false, type: String, description: 'The category of the event.'},
					start_date: {required: true, type: Date, description: 'The start date of the event.'},
					start_time: {required: false, type: Time, description: 'The start time of the event.'},
					end_date: {required: false, type: Date, description: 'The end date of the event.'},
					end_time: {required: false, type: Time, description: 'The end time of the event.'},
					notes: {required: true, type: RichText, description: 'The notes of the event.'},
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

		def post_conditions
			result =
				{
					description: 'Updates an event with the given keys.',
					attributes: self.put_conditions[:attributes].each { |_, v| v[:required] = false }
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
	API.register_resource(TagsResource.new('events', '[eventid]/tags', '[eventid]/tags', Event))

end