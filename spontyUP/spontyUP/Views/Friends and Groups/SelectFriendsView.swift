//
//  SelectFriendsView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 09.12.2024.
//

import SwiftUI

struct SelectFriendsView: View {
    @State private var searchText: String = ""
    @Binding var selectedFriends: [FriendshipWithProfile] // Binding to persist selection
    @State private var availableFriends: [FriendshipWithProfile] = []

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss // Add dismiss environment

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
                                Image(systemName: isSelected(friend) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected(friend) ? .accentColor : .gray)
                            }
                        }
                        .padding()
                        .background(isSelected(friend)
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear)
                        .cornerRadius(8)
                    }
                }
                .navigationTitle("Select Friends")
                .searchable(text: $searchText, prompt: "Search Friends")
                .task {
                    try? await supabase.updateFriendsList()
                    availableFriends = supabase.friendsList
                }

                Button("Confirm Selection") {
                    dismiss() // Dismiss the view
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFriends.isEmpty) // Disable if no friends selected
            }
        }
    }

    private var filteredFriends: [FriendshipWithProfile] {
        availableFriends.filter {
            searchText.isEmpty || $0.friendship.friendUsername.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func isSelected(_ friend: FriendshipWithProfile) -> Bool {
        selectedFriends.contains(where: { $0.friendship.id == friend.friendship.id })
    }

    private func toggleSelection(for friend: FriendshipWithProfile) {
        if let index = selectedFriends.firstIndex(where: { $0.friendship.id == friend.friendship.id }) {
            selectedFriends.remove(at: index) // Deselect
        } else {
            selectedFriends.append(friend) // Select
        }
    }
}


#Preview {
    //SelectFriendsView()
}
