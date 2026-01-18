//
//  CreateEventView.swift
//  spontyUP
//
//  Created by Pascal on 04.12.2024.
//

import SwiftUI

struct ManageEventView: View {
    @State private var showingCreateEventView: Bool = false
    @State private var showingDraftsView: Bool = false
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State var result: Result<Void, Error>?

    @Environment(SupabaseHandler.self) private var supabase

    // Filter events based on search query
    var filteredEvents: [EventWithInvitations] {
        if searchText.isEmpty {
            return supabase.hostedEventsWithInvitationsList
        } else {
            return supabase.hostedEventsWithInvitationsList.filter {
                $0.event.eventTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Create Event and View Drafts Buttons
                HStack(spacing: 8) {
                    Button("Create New Event") {
                        showingCreateEventView = true
                    }
                    .buttonStyle(ProfileActionButtonStyle())
                    .padding(.horizontal)
                    .sheet(
                        isPresented: $showingCreateEventView,
                        onDismiss: handleDismiss
                    ) {
                        CreateEventView()
                    }

                //    Button("View Drafts") {
                //        showingDraftsView = true
                //    }
                //    .buttonStyle(.bordered)
                //    .frame(maxWidth: .infinity)
                //    .contentShape(Rectangle())
                //    .sheet(
                //        isPresented: $showingDraftsView
                //    ) {
                //        EventDraftsView()
                //    }
                }
                
                // Loading or List of Events
                if isLoading {
                    ProgressView("Loading events...")
                        .frame(
                            maxWidth: .infinity, maxHeight: .infinity,
                            alignment: .center)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredEvents) { eventDetails in
                                EventCard(
                                    eventDetails: eventDetails
                                )
                                .navigationTitle("Manage Events")
                                .contentShape(Rectangle())  // Ensure the entire card is tappable
                            }
                            .buttonStyle(PlainButtonStyle())  // Remove default button styling
                        }
                    }
                    .padding(.horizontal)
                    .refreshable {
                        await refreshPage()
                    }

                }

                // Success/Error Messages
                if let result {
                    Section {
                        switch result {
                        case .success:
                            Text("Events fetched successfully.")
                                .foregroundColor(.green)
                        case .failure(let error):
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Manage Events")
            .searchable(text: $searchText, prompt: "Search Events")
            .task {
                isLoading = true
                defer { isLoading = false }
                await refreshPage()
            }
        }
    }

    private func handleDismiss() {
        Task {
            await refreshPage()
        }
    }

    private func refreshPage() async {
        do {
            try await supabase.updateHostedEventsWithInvitationsList()
        } catch {
            print("Failed to refresh feed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ManageEventView()
}
