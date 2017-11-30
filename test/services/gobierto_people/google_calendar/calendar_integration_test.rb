# frozen_string_literal: true

require "test_helper"
require "support/calendar_integration_helpers"

module GobiertoPeople
  module GoogleCalendar
    class CalendarIntegrationTest < ActiveSupport::TestCase
      include ::CalendarIntegrationHelpers

      def richard
        @richard ||= gobierto_people_people(:richard)
      end

      def site
        @site ||= sites(:madrid)
      end

      def google_calendar_id
        "richard@google-calendar.com"
      end

      def setup
        super

        ## Mocks
        date1 = mock
        date1.stubs(date_time: Time.now)
        date2 = mock
        date2.stubs(date_time: 1.hour.from_now)

        # Private event, ignored
        event1 = mock
        event1.stubs(visibility: "private")

        creator_event2 = mock
        creator_event2.stubs(email: google_calendar_id)

        creator_event3 = mock
        creator_event3.stubs(email: google_calendar_id)

        attendee1 = mock
        attendee1.stubs(self?: true, display_name: richard.name, email: google_calendar_id)

        attendee2 = mock
        attendee2.stubs(self?: false, display_name: "Wadus person", email: nil)

        # Single event, organized by richard, with two attendees, from calendar that is not selected
        event7 = mock
        event7.stubs(visibility: nil, location: nil, creator: creator_event2, recurrence: nil, id: "event7",
                     summary: "Event 7", start: date1, end: date2, attendees: [attendee1, attendee2], description: "")

        # Single event, organized by richard, with two attendees
        event2 = mock
        event2.stubs(visibility: nil, location: nil, creator: creator_event2, recurrence: nil, id: "event2",
                     summary: "Event 2", start: date1, end: date2, attendees: [attendee1, attendee2], description: "Event 2 description")

        # Single event, organized by other, calendar shared with Richard
        event3 = mock
        event3.stubs(visibility: nil, location: "Patio de mi casa 1, 28005, Madrid", creator: creator_event3, recurrence: nil, id: "event3",
                     summary: "Event 3", start: date1, end: date2, attendees: [attendee1, attendee2], description: "")

        # Recurring event
        event4 = mock
        event4.stubs(visibility: nil, location: nil, creator: creator_event3, recurrence: ["WEEK=1"], id: "event4",
                     summary: "Event 4", start: date1, end: date2, attendees: [attendee1, attendee2], description: "")


        # Event no start
        event_no_start = mock
        event_no_start.stubs(visibility: nil, location: nil, creator: creator_event3, recurrence: nil, id: "event-no-start",
                             summary: "Event no start", start: nil, end: nil, attendees: [], description: "")

        # Instance 1 of recurring event event4
        event5 = mock
        event5.stubs(visibility: nil, location: nil, creator: creator_event3, recurrence: nil, id: "event4_instance_1",
                     summary: "Event 5", start: date1, end: date2, attendees: [attendee1, attendee2], description: "")

        # Instance 2 of recurring event event4
        event6 = mock
        event6.stubs(visibility: nil, location: nil, creator: creator_event3, recurrence: nil, id: "event4_instance_2",
                     summary: "Event 6", start: date1, end: date2, attendees: [attendee1, attendee2], description: "")

        calendar1 = mock
        calendar1.stubs(id: google_calendar_id, primary?: true)

        calendar2 = mock
        calendar2.stubs(id: 2, primary?: false)

        calendar3 = mock
        calendar3.stubs(id: 3, primary?: false)

        calendar_1_items_response = mock
        calendar_1_items_response.stubs(:items).returns([event1, event2])

        calendar_2_items_response = mock
        calendar_2_items_response.stubs(:items).returns([event3, event4, event_no_start])

        calendar_3_items_response = mock
        calendar_3_items_response.stubs(:items).returns([event7])

        event_4_instances_response = mock
        event_4_instances_response.stubs(:items).returns([event5, event6])

        calendar_items_response = mock
        calendar_items_response.stubs(:items).returns([calendar1, calendar2, calendar3])

        client_options = mock
        client_options.stubs(:application_name=).returns(true)

        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_calendar_lists).returns(calendar_items_response)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_events).with(calendar1.id, instance_of(Hash)).returns(calendar_1_items_response)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_events).with(calendar2.id, instance_of(Hash)).returns(calendar_2_items_response)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_events).with(calendar3.id, instance_of(Hash)).returns(calendar_3_items_response)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:list_event_instances).with(calendar2.id, event4.id).returns(event_4_instances_response)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:client_options).returns(client_options)
        ::Google::Apis::CalendarV3::CalendarService.any_instance.stubs(:authorization=).returns(true)

        ## Configure site and person
        configure_google_calendar_integration(
          collection: richard.calendar,
          data: { calendars: [calendar1.id, calendar2.id] }
        )
      end

      def test_sync_events
        Publishers::Trackable.expects(:broadcast_event).times(3)

        assert_difference "GobiertoCalendars::Event.count", 4 do
          CalendarIntegration.sync_person_events(richard)
        end

        # Event 2 checks
        event = richard.events.find_by external_id: "event2"
        assert_equal "Event 2", event.title
        assert_equal richard, event.collection.container
        assert_empty event.locations
        assert_equal 2, event.attendees.size
        assert_equal richard, event.attendees.first.person
        assert_nil event.attendees.second.person
        assert_equal "Wadus person", event.attendees.second.name
        assert_equal "Event 2 description", event.description

        # Event 3 checks
        event = site.events.find_by external_id: "event3"
        assert_equal "Event 3", event.title
        assert_equal richard, event.collection.container
        assert_equal "Patio de mi casa 1, 28005, Madrid", event.locations.first.name
        assert_equal 2, event.attendees.size
        assert_equal richard, event.attendees.first.person
        assert_equal "Wadus person", event.attendees.second.name

        # Event 5 checks
        event = site.events.find_by external_id: "event4_instance_1"
        assert_equal "Event 5", event.title
        assert_equal richard, event.collection.container
        assert_empty event.locations
        assert_equal 2, event.attendees.size
        assert_equal richard, event.attendees.first.person
        assert_equal "Wadus person", event.attendees.second.name

        # Event 6 checks
        event = site.events.find_by external_id: "event4_instance_2"
        assert_equal "Event 6", event.title
        assert_equal richard, event.collection.container
        assert_empty event.locations
        assert_equal 2, event.attendees.size
        assert_equal richard, event.attendees.first.person
        assert_equal "Wadus person", event.attendees.second.name
      end

      def test_sync_events_updates_event_attributes
        CalendarIntegration.sync_person_events(richard)

        event = richard.events.find_by external_id: "event2"
        event.title = "Event 2 updated"
        event.save

        CalendarIntegration.sync_person_events(richard)

        event.reload
        assert_equal "Event 2", event.title
      end

      def test_sync_events_removes_deleted_event_attributes
        CalendarIntegration.sync_person_events(richard)

        event = richard.events.find_by external_id: "event2"
        GobiertoCalendars::EventLocation.create!(event: event, name: "I'll be deleted")

        CalendarIntegration.sync_person_events(richard)

        event.reload
        assert event.locations.empty?
      end

      def test_sync_attendees
        CalendarIntegration.sync_person_events(richard)

        event = richard.events.find_by external_id: "event2"
        event.attendees.second.delete

        CalendarIntegration.sync_person_events(richard)

        event.reload
        assert_equal 2, event.attendees.reload.size
      end
    end
  end
end
