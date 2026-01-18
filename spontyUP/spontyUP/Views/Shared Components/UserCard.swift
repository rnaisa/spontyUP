//
//  UserCard.swift
//  spontyUP
//
//  Created by Pascal on 14.12.2024.
//

import SwiftUI

struct UserCard: View {
    @State private var showEditProfileView: Bool = false
    @Environment(SupabaseHandler.self) private var supabase
    
    var friendsCount: Int
    var groupsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let userDetails = supabase.currentUserProfile {
                    // Profile Image
                    Circle()
                        .fill(Color.purple) // Placeholder color
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userDetails.fullName ?? "")
                            .font(.headline)
                        Text(userDetails.username)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button("Edit Profile") {
                        showEditProfileView = true
                    }
                    .sheet(isPresented: $showEditProfileView, onDismiss: {
                        handleDismiss()
                    }) {
                        EditProfileView()
                    }
                }
            }

            HStack {
                Button("\(friendsCount) \(friendsCount == 1 ? "Friend" : "Friends")") {
                    // Open FriendsAndGroupsView for friends
                }
                .buttonStyle(FriendsGroupsButtonStyle())

                Button("\(groupsCount) \(groupsCount == 1 ? "Group" : "Groups")") {
                    // Open FriendsAndGroupsView for groups
                }
                .buttonStyle(FriendsGroupsButtonStyle())
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func handleDismiss() {
        Task {
            do {
                try await supabase.updateCurrentUserProfileVariable()
            } catch {
                print("Update failed: \(error.localizedDescription)")
            }
        }
    }
}


// Custom Button Style for Friends/Groups
struct FriendsGroupsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
    }
}



#Preview {
    UserCard(
        friendsCount: 42,
        groupsCount: 4
    )
}

