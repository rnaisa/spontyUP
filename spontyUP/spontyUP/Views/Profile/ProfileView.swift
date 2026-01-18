//
//  ProfileView.swift
//  spontyUP
//
//  Created by Pascal on 04.12.2024.
//

import SwiftUI

struct ProfileView: View {
    
    @State var result: Result<Void, Error>?
    
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(UserSettings.self) private var userSettings
    
    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 16) {
                        UserCard(
                            friendsCount: supabase.friendsList.count,
                            groupsCount: supabase.groupsList.count
                        )
                        NavigationLink(destination: ManageEventView()) {
                            Text("My Events")
                        }
                        .buttonStyle(ProfileActionButtonStyle())
                        
                    /// removed because of time constraints
                    //  NavigationLink(destination: EventDraftsView()) {
                    //      Text("Event Drafts")
                    //  }
                    //  .buttonStyle(ProfileActionButtonStyle())
                        
                    }
                    .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign out", role: .destructive) {
                        signOutButtonTapped()
                    }
                }
            }
            
            if let result {
                Section {
                    switch result {
                    case .success:
                        Text("Profile updated successfully!")
                            .foregroundColor(.green)
                    case .failure(let error):
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            try? await supabase.updateCurrentUserProfileVariable()
            try? await supabase.updateFriendsList()
            try? await supabase.updateGroupsList()
        }
    }

    func signOutButtonTapped() {
        Task {
            do {
                try await supabase.signOut()
                result = .success(())
                print("Signed out successfully!")
            } catch {
                result = .failure(error)
                print("Failed to sign out: \(error.localizedDescription)")
            }
        }
    }
}

// Custom Button Style
struct ProfileActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.1 : 0.5))
            .foregroundColor(.primary)
            .cornerRadius(8)
    }
}

#Preview {
    ProfileView()
        .environment(SupabaseHandler.shared)
        .environment(UserSettings.shared)
}
