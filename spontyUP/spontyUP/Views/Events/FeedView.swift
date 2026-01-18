//
//  FeedView.swift
//  spontyUP
//
//  Created by Pascal on 04.12.2024.
//

import SwiftUI

struct FeedView: View {
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var isEditingEvent: Bool = false
    @State private var eventToEdit: EventWithInvitations?

    @Environment(SupabaseHandler.self) private var supabase

    // Filter events based on search query
    var filteredEvents: [EventWithInvitations] {
        let active = Date(timeInterval: -86400, since: Date()) // Current date and time - 24h
        
        let sortedEvents = supabase.eventsWithInvitiationsList
            .filter {
                $0.event.eventDate >= active
            }
            .sorted { $0.event.eventDate < $1.event.eventDate }
        
        if searchText.isEmpty {
            return sortedEvents
        } else {
            return sortedEvents.filter {
                $0.event.eventTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading events...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(filteredEvents) { eventDetails in
                                EventCard(
                                    eventDetails: eventDetails
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "Search Events")
            .task {
                isLoading = true
                defer { isLoading = false }
                await refreshFeed()
            }
            .refreshable {
                await refreshFeed()
            }
        }
    }

    private func refreshFeed() async {
        do {
            try await supabase.updateEventsWithInvitationsList()
            supabase.eventsWithInvitiationsList.sort {
                $0.event.eventDate > $1.event.eventDate
            }
        } catch {
            print("Failed to refresh feed: \(error.localizedDescription)")
        }
    }
}


#Preview {
    FeedView()
        .environment(SupabaseHandler.shared)
}
