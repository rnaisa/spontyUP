//
//  FriendDetailView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 14.12.2024.
//

import SwiftUI

struct FriendDetailView: View {
    var friend: FriendshipWithProfile
    @State private var selectedFriendGroups: [FriendGroup] = []
    @State private var groupsOfFriend: [FriendGroup] = []
    @State private var showAddGroupsView: Bool = false

    @Environment(SupabaseHandler.self) private var supabase

    var body: some View {
        VStack {
            // Display Name Section
            Text(friend.profile.username)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            if let fullName = friend.profile.fullName {
                Text(fullName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // List with Section for Button and Groups
            List {
                // Section for the Button
                Section {
                    Button(action: {
                        showAddGroupsView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add to Groups")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Section for the Groups List
                Section(header: Text("Groups")) {
                    ForEach(groupsOfFriend, id: \.id) { group in
                        Text("Group: \(group.name)")
                    }
                }
            }
            .listStyle(.insetGrouped) // Optional: Modern list style
            .sheet(isPresented: $showAddGroupsView) {
                AddGroupsToView(
                    existingGroups: groupsOfFriend,
                    onSelectionCompleted: { selectedGroups in
                        selectedFriendGroups = selectedGroups
                        Task {
                            await saveSelectedGroupsToFriend()
                        }
                    }
                )
            }
            .task {
                await loadGroupsOfFriend()
            }
        }
    }

    // Load existing group members
    private func loadGroupsOfFriend() async {
        do {
            groupsOfFriend = try await supabase.fetchGroupsOfFriend(friend: friend)
        } catch {
            print("Error loading groups: \(error)")
        }
    }

    // Save newly selected friends to the group
    private func saveSelectedGroupsToFriend() async {
        do {
            let membersToAdd = selectedFriendGroups.map {
                CreateGroupMemberParams(
                    groupId: $0.id, friendId: friend.profile.id,
                    friendshipId: friend.friendship.friendshipId)
            }
            try await supabase.createGroupMembers(members: membersToAdd)
            await loadGroupsOfFriend()  // Reload updated group members
        } catch {
            print("Error saving group members: \(error)")
        }
    }
}

#Preview {
    //FriendDetailView()
}
