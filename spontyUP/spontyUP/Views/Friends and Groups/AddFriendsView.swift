//
//  AddFriendsView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 09.12.2024.
//

import SwiftUI
import Toasts

struct AddFriendsView: View {
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var profilesFound: [Profile] = []

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.presentToast) var presentToast

    var body: some View {
        NavigationStack {
            VStack {
                List(profilesFound) { user in
                    HStack {
                        Text(user.username)
                        Spacer()
                        if supabase.sentFriendRequestsProfileList.contains(where: { $0.id == user.id })
                        {
                            Button(action: {
                                Task {
                                    let toast = ToastValue(
                                        message: "Friend request already sent!"
                                    )
                                    presentToast(toast)
                                }
                            }) {
                                
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.accentColor)
                            }
                        } else {
                            Button(action: {
                                Task {
                                    await sendFriendRequest(to: user)
                                }
                            }) {

                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }

                    }
                }
                .navigationTitle("Add Friends")
                .searchable(text: $searchText, prompt: "Search Users")
                .onChange(of: searchText) { _, _ in
                    Task {
                        await searchUsers()
                    }
                }

                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                }
            }
        }.task {
            try? await supabase.updateSentFriendRequestsList()
        }
    }

    private func searchUsers() async {
        guard !searchText.isEmpty else {
            profilesFound = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            profilesFound = try await supabase.searchUsers(
                searchText: searchText)
        } catch {
            print("Error searching users: \(error)")
            profilesFound = []
        }
    }

    private func sendFriendRequest(to user: Profile) async {
        do {
            try await supabase.sendFriendRequest(receiverId: user.id)
            
            try await supabase.updateSentFriendRequestsList()

            let toast = ToastValue(
                message: "Friend request sent to \(user.username)!"
            )
            presentToast(toast)
        } catch {
            print("Sending friend request failed.")
        }
    }
}

#Preview {
    //AddFriendsView()
}
