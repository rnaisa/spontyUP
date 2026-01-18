//
//  EventDraftsView.swift
//  spontyUP
//
//  Created by Pascal on 05.12.2024.
//


// not used/referenced in the app right now because of time constraints - we left it out to not have unfinished and buggy views in the final submission


import SwiftUI

struct EventDraftsView: View {
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false

    @Environment(SupabaseHandler.self) private var supabase

    // Filter events to only show drafts
    var draftEvents: [EventWithInvitations] {
        supabase.hostedEventsWithInvitationsList.filter {
            $0.event.eventStatus == "Draft" &&
            (searchText.isEmpty || $0.event.eventTitle.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading drafts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List(draftEvents) { eventDetails in
                            EventCard(
                                eventDetails: eventDetails
                            )
                            .navigationTitle("Event Drafts")
                            .contentShape(Rectangle())
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await refreshDrafts()
                    }
                }
            }
            .navigationTitle("Draft Events")
            .searchable(text: $searchText, prompt: "Search Drafts")
            .task {
                isLoading = true
                defer { isLoading = false }
                await refreshDrafts()
            }
        }
    }

    private func refreshDrafts() async {
        do {
            try await supabase.updateHostedEventsWithInvitationsList()
        } catch {
            print("Failed to refresh drafts: \(error.localizedDescription)")
        }
    }
}

#Preview {
    EventDraftsView()
        .environment(SupabaseHandler.shared)
}
