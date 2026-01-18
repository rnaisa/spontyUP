//
//  CreateEvent.swift
//  spontyUP
//
//  Created by Pascal on 05.12.2024.
//

import SwiftUI

struct CreateEventView: View {
    @State private var eventTitle: String = ""
    @State private var eventDate = Date()
    @State private var eventLocation: String = ""
    @State private var eventDescription: String = ""
    @State private var isOpenCircle: Bool = false
    
    @State private var isCreating: Bool = false
    @State private var eventMembers: [FriendshipWithProfile] = []
    @State private var eventGroups: [FriendGroup] = []

    @State var result: Result<Void, Error>?

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss  // Environment value to dismiss the sheet

    var body: some View {
        NavigationStack {
            Form {
                // Event Details Section
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $eventTitle)
                    DatePicker(
                        "Event Date", selection: $eventDate,
                        displayedComponents: [.date, .hourAndMinute])
                        
                    TextField("Event Location", text: $eventLocation)
                    TextField(
                        "Event Description", text: $eventDescription,
                        axis: .vertical
                    )
                    .lineLimit(5)
                }

                    Section(header: Text("Members")) {
                        NavigationLink(
                            destination: SelectFriendsView(
                                selectedFriends: $eventMembers)
                        ) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                                Text("Add Friends")
                                    .foregroundColor(.primary)
                            }
                        }

                        List(eventMembers) { friend in
                            Text(friend.friendship.friendUsername)
                        }

                        NavigationLink(
                            destination: SelectGroupsView(
                                selectedGroups: $eventGroups)
                        ) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                                Text("Add Groups")
                                    .foregroundColor(.primary)
                            }
                        }

                        List(eventGroups) { group in
                            Text(group.name)
                        }
                    }
                
                Section(header: Text("Settings")) {
                    Toggle("Allow Friends Of Friends", isOn: $isOpenCircle)
                        .tint(Color.accentColor)
                }
                
            }

            // Create Button
            Button(action: createEvent) {
                if isCreating {
                    ProgressView()
                } else {
                    Text("Create Event")
                }
            }
            .buttonStyle(ProfileActionButtonStyle())
            .disabled(
                isCreating || eventTitle.isEmpty || eventLocation.isEmpty
                || eventDescription.isEmpty || (eventMembers.isEmpty && eventGroups.isEmpty) )

            if let result {
                Section {
                    switch result {
                    case .success:
                        Text("Event created successfully.")
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Create Event")
    }

    private func createEvent() {
        Task {
            isCreating = true
            do {

                let returnedEvent = try await supabase.createAndReturnEvent(
                    title: eventTitle,
                    date: eventDate,
                    location: eventLocation,
                    description: eventDescription,
                    isOpenCircle: isOpenCircle
                )

                let allGroupMembers =
                    try await supabase.fetchAllGroupMembersWithProfiles(
                        groups: eventGroups)

                // Extract the IDs of group members and event members
                let invitedGroupMemberIds = allGroupMembers.map { $0.profile.id }
                let invitedFriendMemberIds = eventMembers.map { $0.profile.id }

                // Combine both groups and remove duplicates
                let invitedMembers = Set(invitedGroupMemberIds + invitedFriendMemberIds)

                let members = invitedMembers.map {
                    CreateInvitationParams(
                        eventId: returnedEvent.id,
                        senderId: returnedEvent.eventCreatorUserId,
                        receiverId: $0)
                }

                try await supabase.createInvitation(members: members)
                print(members)

                result = .success(())

                // Clear form fields
                eventTitle = ""
                eventDate = Date()
                eventLocation = ""
                eventDescription = ""
                dismiss()  // Dismiss the sheet on success
            } catch {
                result = .failure(error)
            }
            isCreating = false
        }
    }

}

#Preview {
    NavigationStack {
        ManageEventView()
    }
}
