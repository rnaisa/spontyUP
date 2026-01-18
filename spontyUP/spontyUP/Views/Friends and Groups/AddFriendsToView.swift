//
//  AddFriendsToView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 15.12.2024.
//

import SwiftUI

struct AddFriendsToView: View {
    @State private var searchText: String = ""
    @State var selectedFriends: [FriendshipWithProfile] = []
    @State private var availableFriends: [FriendshipWithProfile] = []

    let existingMembers: [FriendshipWithProfile]  // Members already in the group
    let onSelectionCompleted: ([FriendshipWithProfile]) -> Void

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss  // Add dismiss environment

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(filteredFriends, id: \.friendship.id) { friend in
                        HStack {
                            Text(friend.profile.username)
                            Spacer()
                            Button(action: {
                                toggleSelection(for: friend)
                            }) {
                                Image(
                                    systemName: isSelected(friend)
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundColor(
                                    isSelected(friend) ? .accentColor : .gray)
                            }
                        }
                        .padding()
                        .background(
                            isSelected(friend)
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
                .navigationTitle("Select Friends")
                .searchable(text: $searchText, prompt: "Search Friends")
                .task {
                    await loadAvailableFriends()
                }

                Button("Confirm Selection") {
                    onSelectionCompleted(selectedFriends)
                    dismiss()  // Dismiss the view
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFriends.isEmpty)  // Disable if no friends selected
            }
        }
    }

    // Filter friends to exclude existing members
    private var filteredFriends: [FriendshipWithProfile] {
        availableFriends
            .filter { friend in
                !existingMembers.contains(where: {
                    $0.friendship.id == friend.friendship.id
                })
                    && (searchText.isEmpty
                        || friend.profile.username
                            .localizedCaseInsensitiveContains(searchText))
            }
    }

    private func isSelected(_ friend: FriendshipWithProfile) -> Bool {
        selectedFriends.contains(where: {
            $0.friendship.id == friend.friendship.id
        })
    }

    private func toggleSelection(for friend: FriendshipWithProfile) {
        if let index = selectedFriends.firstIndex(where: {
            $0.friendship.id == friend.friendship.id
        }) {
            selectedFriends.remove(at: index)  // Deselect
        } else {
            selectedFriends.append(friend)  // Select
        }
    }

    private func loadAvailableFriends() async {
        // Replace this with actual fetching logic
        try? await supabase.updateFriendsList()
        availableFriends = supabase.friendsList
    }
}

#Preview {
    //SelectFriendsView()
}

#Preview {
    //AddFriendsToGroupView()
}
