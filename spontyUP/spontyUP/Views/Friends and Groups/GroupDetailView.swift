//
//  GroupDetailView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 09.12.2024.
//

import SwiftUI

struct GroupDetailView: View {
    var group: FriendGroup
    @State private var selectedGroupFriends: [FriendshipWithProfile] = [] // New members added
    @State private var groupMembers: [FriendshipWithProfile] = [] // Existing members
    @State private var showAddGroupMembersView: Bool = false

    @Environment(SupabaseHandler.self) private var supabase

    var body: some View {
        VStack {
            // Group Name Section
            Text(group.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.vertical)

            // List with Actions and Members
            List {
                // Section for "Add Member" button
                Section {
                    Button(action: {
                        showAddGroupMembersView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add Member")
                                .foregroundColor(.primary)
                        }
                    }
                }

                // Section for Group Members
                Section(header: Text("Members")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    ForEach(groupMembers, id: \.friendship.id) { member in
                        HStack {
                            Text(member.profile.username)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            if let fullName = member.profile.fullName {
                                Text(fullName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped) // Modern list styling
            .sheet(isPresented: $showAddGroupMembersView) {
                AddFriendsToView(
                    existingMembers: groupMembers,
                    onSelectionCompleted: { selectedFriends in
                        selectedGroupFriends = selectedFriends
                        Task {
                            await saveSelectedFriendsToGroup()
                        }
                    }
                )
            }
            .task {
                await loadGroupMembers()
            }
        }
    }

    // Load existing group members
    private func loadGroupMembers() async {
        do {
            groupMembers = try await supabase.fetchFriendshipsWithProfilesInGroup(group: group)
        } catch {
            print("Error loading group members: \(error)")
        }
    }

    // Save newly selected friends to the group
    private func saveSelectedFriendsToGroup() async {
        do {
            let membersToAdd = selectedGroupFriends.map {
                CreateGroupMemberParams(groupId: group.id, friendId: $0.friendship.friendId, friendshipId: $0.friendship.friendshipId)
            }
            try await supabase.createGroupMembers(members: membersToAdd)
            await loadGroupMembers() // Reload updated group members
        } catch {
            print("Error saving group members: \(error)")
        }
    }
}
