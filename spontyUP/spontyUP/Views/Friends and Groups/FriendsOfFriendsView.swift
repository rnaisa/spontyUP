//
//  FriendsOfFriendsView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 16.12.2024.
//

import SwiftUI

struct FriendsOfFriendsView: View {
    var eventId: UUID
    var hostId: UUID
    
    @State private var selectedFriendsToAdd: [FriendshipWithProfile] = []  // New members added
    @State private var addedFriendsToEvent: [FriendshipWithProfile] = []  // Existing members
    @State private var showAddFriendsToEventView: Bool = false
    @State private var friendsToExclude: [FriendshipWithProfile] = []
    

    @Environment(SupabaseHandler.self) private var supabase

    var body: some View {
        NavigationStack {
            List {
                // Actions Section
                Section(header: Text("Actions")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    Button(action: {
                        showAddFriendsToEventView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor) // Icon in accent color
                            Text("Invite Friends")
                                .foregroundColor(.primary) // Text in default primary color
                        }
                    }
                    .sheet(isPresented: $showAddFriendsToEventView, onDismiss: handleDismiss) {
                        AddFriendsToView(
                            existingMembers: friendsToExclude,
                            onSelectionCompleted: { selectedFriends in
                                selectedFriendsToAdd = selectedFriends
                                Task {
                                    await saveSelectedFriendsToEvent()
                                }
                            }
                        )
                    }
                }
                
                // Invited Friends Section
                Section(header: Text("Invited Friends")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    ForEach(addedFriendsToEvent, id: \.friendship.id) { member in
                        Text("\(member.profile.username)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Invited Friends")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadInvitedFriends()
            }
        }

    }
    
    private func handleDismiss() {
        Task {
            await loadInvitedFriends()
        }
    }

    // Load existing group members
    private func loadInvitedFriends() async {
        do {
            let creatorProfile = try await supabase.fetchFriendshipsWithProfileOfUser(userId: hostId)
            addedFriendsToEvent =
                try await supabase.fetchFriendshipsWithProfilesAddedToEvent(
                    eventId: eventId)
            
            // exclude already invited friends + event creator
            friendsToExclude = addedFriendsToEvent + [creatorProfile]
            
            
        } catch {
            print("Error loading group members: \(error)")
        }
    }

    // Save newly selected friends to the group
    private func saveSelectedFriendsToEvent() async {
        do {

            let invitedFriendMemberIds = selectedFriendsToAdd.map {
                $0.profile.id
            }

            let existingInvitationsIds = addedFriendsToEvent.map {
                $0.profile.id
            }

            // Combine both groups and remove duplicates
            let invitedMembers = Set(
                existingInvitationsIds + invitedFriendMemberIds)

            try await supabase.createInvitation(eventId: eventId, members: invitedMembers)
            await loadInvitedFriends()
        } catch {
            print("Error saving group members: \(error)")
        }
    }
}
