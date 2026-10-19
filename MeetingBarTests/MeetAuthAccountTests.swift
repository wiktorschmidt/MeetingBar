//
//  MeetAuthAccountTests.swift
//  MeetingBarTests
//

import XCTest

@testable import MeetingBar

final class MeetAuthAccountTests: XCTestCase {
    private func makeMeetEvent(calendar: MBCalendar, attendees: [MBEventAttendee] = []) -> MBEvent {
        MBEvent(
            id: "meet_event",
            lastModifiedDate: nil,
            title: "Meet event",
            status: .confirmed,
            notes: nil,
            location: "https://meet.google.com/abc-defg-hij",
            url: nil,
            organizer: nil,
            attendees: attendees,
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            isAllDay: false,
            recurrent: false,
            calendar: calendar
        )
    }

    func test_sharedCalendarSyncedThroughEventKit_usesCalendarOwner() {
        // Work calendar subscribed in a private Google account: EventKit reports the private
        // account as the source and as the current user.
        let calendar = MBCalendar(title: "wiktor@netguru.com", id: "8F1C-UUID", source: "Google",
                                  email: "wiktorschmidt@gmail.com", color: .black)
        let event = makeMeetEvent(calendar: calendar, attendees: [
            MBEventAttendee(email: "wiktorschmidt@gmail.com", status: .accepted, isCurrentUser: true),
            MBEventAttendee(email: "wiktor@netguru.com", status: .accepted)
        ])

        XCTAssertEqual(event.meetingLink?.url.absoluteString,
                       "https://meet.google.com/abc-defg-hij?authuser=wiktor@netguru.com")
    }

    func test_sharedCalendarFromGoogleAPI_usesCalendarID() {
        let calendar = MBCalendar(title: "Netguru", id: "wiktor@netguru.com", source: "wiktorschmidt@gmail.com",
                                  email: "wiktorschmidt@gmail.com", color: .black)
        let event = makeMeetEvent(calendar: calendar)

        XCTAssertEqual(event.meetingLink?.url.absoluteString,
                       "https://meet.google.com/abc-defg-hij?authuser=wiktor@netguru.com")
    }

    func test_groupCalendar_fallsBackToCurrentUserAttendee() {
        let calendar = MBCalendar(title: "Team", id: "abc123@group.calendar.google.com", source: nil,
                                  email: "wiktorschmidt@gmail.com", color: .black)
        let event = makeMeetEvent(calendar: calendar, attendees: [
            MBEventAttendee(email: "wiktor@netguru.com", status: .accepted, isCurrentUser: true)
        ])

        XCTAssertEqual(event.meetingLink?.url.absoluteString,
                       "https://meet.google.com/abc-defg-hij?authuser=wiktor@netguru.com")
    }

    func test_calendarWithoutOwnerEmail_fallsBackToSourceAccount() {
        let calendar = MBCalendar(title: "Work", id: "8F1C-UUID", source: "Google",
                                  email: "wiktor@netguru.com", color: .black)
        let event = makeMeetEvent(calendar: calendar)

        XCTAssertEqual(event.meetingLink?.url.absoluteString,
                       "https://meet.google.com/abc-defg-hij?authuser=wiktor@netguru.com")
    }

    func test_isPersonalGoogleAccountEmail() {
        XCTAssertTrue(isPersonalGoogleAccountEmail("wiktor@netguru.com"))
        XCTAssertFalse(isPersonalGoogleAccountEmail("abc@group.calendar.google.com"))
        XCTAssertFalse(isPersonalGoogleAccountEmail("en.polish#holiday@group.v.calendar.google.com"))
        XCTAssertFalse(isPersonalGoogleAccountEmail("Work"))
        XCTAssertFalse(isPersonalGoogleAccountEmail("8F1C-UUID"))
    }
}
