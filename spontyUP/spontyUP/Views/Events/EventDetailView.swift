//
//  EventDetailTestView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 15.12.2024.
//

import SwiftUI

struct EventDetailView: View {
    var event: EventWithInvitations
    @Environment(SupabaseHandler.self) private var supabase

    @State private var guestList: [Profile] = []
    @State private var isDescriptionExpanded: Bool = false
    @State private var title: String = ""
    @State private var date: Date =  Date()
    @State private var description: String = ""
    @State private var location: String = ""
    @State private var isHost: Bool = false
    @State private var currentUserStatus: InvitationStatus = .pending

    // TODO: as soon as the updateDetails() function fetches profiles instead of UUID, change to [Profile]
    @State private var participatingList: [Profile] = []
    @State private var pendingList: [Profile] = []
    @State private var declinedList: [Profile] = []
    @State private var isEditingEvent: Bool = false

    var body: some View {
        Group {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Event Date and Title
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(
                                    date,
                                    format: .dateTime.year().month().day().hour()
                                        .minute()
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        // Event Description with Expand/Collapse logic
                        VStack(alignment: .leading, spacing: 8) {
                            Text(description)
                                .font(.body)
                                .lineLimit(isDescriptionExpanded ? nil : 4)
                                .animation(.easeInOut, value: isDescriptionExpanded)
                            
                            if description.split(separator: "\n").count
                                > 4
                                || description.count > 200
                            {
                                Button(action: {
                                    isDescriptionExpanded.toggle()
                                }) {
                                    Text(
                                        isDescriptionExpanded
                                        ? "Show Less" : "Show More"
                                    )
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Event Location
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if isHost {
                            renderHostView()
                        } else {
                            renderInviteeView()
                        }
                        
                    }.padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
        } .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await updateDetails()
            }
    }

    @MainActor
    private func updateDetails() async {
        do {
            
            // Fetch event details
            let returnedDetails = try await supabase.fetchEventWithInvitations(
                eventId: event.event.id)

            title = returnedDetails.event.eventTitle
            description = returnedDetails.event.eventDescription
            location = returnedDetails.event.eventLocation
            date = returnedDetails.event.eventDate
            isHost = returnedDetails.isCurrentUserHost
            
            try await supabase.updateCurrentUserProfileVariable()
            
            if let currentUser = supabase.currentUserProfile {
                if let invitation = returnedDetails.invitations.first(where: { $0.receiverId == currentUser.id }) {
                    currentUserStatus = invitation.status
                } else {
                    print("No invitation found for the current user.")
                }
            } else {
                print("Current user ID is nil.")
            }
            
            // Get all invited user IDs
            let guestListIds = returnedDetails.invitations.map { $0.receiverId }

            // Fetch guest profiles
            guestList = try await supabase.client
                .from("profiles")
                .select()
                .in("id", values: guestListIds)
                .execute()
                .value

            // Group invitation statuses
            let groupedIds = Dictionary(
                grouping: returnedDetails.invitations, by: { $0.status })

            // Extract IDs for each status
            let participatingIds = Set(
                groupedIds[.accepted]?.map { $0.receiverId } ?? [])
            let pendingIds = Set(
                groupedIds[.pending]?.map { $0.receiverId } ?? [])
            let declinedIds = Set(
                groupedIds[.declined]?.map { $0.receiverId } ?? [])

            // Filter guest list based on status
            participatingList = filterGuestList(for: participatingIds)
            pendingList = filterGuestList(for: pendingIds)
            declinedList = filterGuestList(for: declinedIds)

        } catch {
            print("Error in updateDetails: \(error.localizedDescription)")
        }
    }

    private func filterGuestList(for ids: Set<UUID>) -> [Profile] {
        guestList.filter { ids.contains($0.id) }
    }

    private func handleDismiss() {
        Task {
            await updateDetails()
        }
    }

    // Host-specific content
    @ViewBuilder
    private func renderHostView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Guest List Breakdown

            NavigationLink(
                destination: GuestListView(
                    title: "Invited", profileList: guestList
                ),
                label: {
                    VStack(alignment: .leading) {
                        Text("Guest List (\(guestList.count))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            )

            renderGuestListSection(
                title: "Participating", list: participatingList)
            renderGuestListSection(title: "Pending", list: pendingList)
            renderGuestListSection(title: "Declined", list: declinedList)

            // Edit and Cancel Buttons
            Button("Edit Event") {
                isEditingEvent = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $isEditingEvent, onDismiss: handleDismiss) {
                EditEventView(eventId: event.event.id)
            }
        }
    }

    /// Invitee-specific content
    @ViewBuilder
    private func renderInviteeView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Participants Section
            renderGuestListSection(
                title: "Participating", list: participatingList)

            // Status and Actions
            if currentUserStatus == .accepted {
                Text("You are attending \(event.event.eventTitle)")
                    .font(.footnote)
                    .foregroundColor(.green)
            } else if currentUserStatus == .declined {
                Text("You declined \(event.event.eventTitle)")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            
            // Show Accept/Decline Buttons for Pending Invites
            if currentUserStatus == .pending {
                HStack {
                    Button(action: { acceptInvitation() }) {
                        Text("Accept")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: { declineInvitation() }) {
                        Text("Decline")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }
            }

            if currentUserStatus == .accepted {
                NavigationLink(
                    destination: FriendsOfFriendsView(
                        eventId: event.event.id, hostId: event.event.eventCreatorUserId)
                ) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                        Text("Invite more friends")
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.2)) // Light accent-colored background
                    .cornerRadius(8)
                }
            }
        }
    }
    
    /// Accept event invitaion
    private func acceptInvitation() {
        Task {
            do {
                try await supabase.updateInboxInvitation(event: event.event, status: .accepted)
                currentUserStatus = .accepted
                print("Invitation accepted")
            } catch {
                print("Failed to accept invitation: \(error)")
            }
        }
    }

    /// decline event invitation
    private func declineInvitation() {
        Task {
            do {
                try await supabase.updateInboxInvitation(event: event.event, status: .declined)
                currentUserStatus = .declined
                print("Invitation declined")
            } catch {
                print("Failed to decline invitation: \(error)")
            }
        }
    }

    /// Guest list section for Host View
    @ViewBuilder
    private func renderGuestListSection(title: String, list: [Profile])
        -> some View
    {
        NavigationLink(
            destination: GuestListView(
                title: title, profileList: list
            ),
            label: {
                VStack(alignment: .leading) {
                    Text("\(title) (\(list.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    renderGuestCircles(count: list.count)
                }
            }
        )
    }

    /// Guest Circles (overlapping circles for participants)
    @ViewBuilder
    private func renderGuestCircles(count: Int) -> some View {
        HStack {
            ZStack {
                ForEach((0..<min(3, count)).reversed(), id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(1))
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                        .offset(x: CGFloat(index * -20))
                }
            }
            if count > 3 {
                Text("+ \(count - 3)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, CGFloat((min(3, count) - 1) * 20))
    }
}

struct GuestListView: View {
    var title: String
    var profileList: [Profile]

    var body: some View {
        Group {
            if profileList.isEmpty {
                Text("No \(title) Users.")
            } else {
                List(profileList) { profile in
                    Text("\(profile.username)")
                }
            }
        }.navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}



#Preview {
    //EventDetailTestView()
}
