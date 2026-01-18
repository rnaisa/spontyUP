//
//  InboxView.swift
//  spontyUP
//
//  Created by Pascal on 04.12.2024.
//

import SwiftUI
import Toasts

enum InboxSubTab: String, CaseIterable {
    case invitations = "Invitations"
    case friendRequests = "Friend Requests"
}

struct InboxView: View {
    @Environment(SupabaseHandler.self) private var supabase
    @State private var selectedSubTab: InboxSubTab = .invitations

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    // Custom background that matches the Picker's height
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.2)) // Background color for unselected options
                            .frame(height: geometry.size.height) // Match the height of the Picker
                            .padding(.horizontal)
                    }

                    // The Picker itself
                    Picker("SubTabs", selection: $selectedSubTab) {
                        ForEach(InboxSubTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .tint(Color.accentColor)
                    .padding(.horizontal)
                }
                .frame(height: 32) // Optional: Ensure the container height is consistent with default Picker height
                
                if selectedSubTab == .invitations {
                    InvitationsListView()
                } else if selectedSubTab == .friendRequests {
                    FriendRequestsListView()
                }
                Spacer()
            }
            .navigationTitle("Inbox")
        }
    }
}

struct InvitationsListView: View {
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.presentToast) var presentToast

    var body: some View {
        NavigationStack {
            if supabase.inboxEventsWithInvitationsList.isEmpty {
                // Display a message when the list is empty
                VStack {
                    Text("No Invitations")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                List(supabase.inboxEventsWithInvitationsList) { inboxEvent in
                    NavigationLink(destination: EventDetailView(event: inboxEvent)) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Event Details
                            Text("Date: \(inboxEvent.event.eventDate, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Event Title
                            Text(inboxEvent.event.eventTitle)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                                .frame(height: 4)
                            
                            // Accept/Decline Buttons
                            HStack {
                                Button(action: { acceptInvitation(event: inboxEvent.event) }) {
                                    Text("Accept")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                                
                                Button(action: { declineInvitation(event: inboxEvent.event) }) {
                                    Text("Decline")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contentShape(Rectangle())
                            }
                        }
                        .listRowBackground(Color.accentColor.opacity(0.1)) // Ensure no background tap
                        .contentShape(Rectangle())      // Makes only visible content tappable
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }.navigationTitle("Invitations")
        .task {
            try? await supabase.updateInboxEventsWithInvitationsList()
        }
    }
    
    private func acceptInvitation(event: Event) {
        Task {
            do {
                try await supabase.updateInboxInvitation(event: event, status: InvitationStatus.accepted)
                
                try await supabase.updateInboxEventsWithInvitationsList()
                
                print("Invitation accepted: \(event)")
                let toast = ToastValue(
                  message: "Invitation accepted!"
                )
                presentToast(toast)
            } catch {
                print("Failed to update invitation.")
            }
        }
    }
    
    private func declineInvitation(event: Event) {
        Task {
            do {
                try await supabase.updateInboxInvitation(event: event, status: InvitationStatus.declined)
                
                try await supabase.updateInboxEventsWithInvitationsList()

                print("Invitation declined: \(event)")
                let toast = ToastValue(
                  message: "Invitation declined!"
                )
                presentToast(toast)
            } catch {
                print("Failed to update invitation.")
            }
        }
    }
}

struct FriendRequestsListView: View {
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.presentToast) var presentToast
    

    var body: some View {
        NavigationStack {
            if supabase.friendRequestsList.isEmpty {
                // Display a message when the list is empty
                VStack {
                    Text("No Friend Requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                // Show the list when there are friend requests
                List(supabase.friendRequestsList) { request in
                    VStack(alignment: .leading, spacing: 8) {
                        // Friend Details
                        Text("Username:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(request.profile.username)
                            .font(.title2)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer().frame(height: 4)
                        
                        // Accept/Decline Buttons
                        HStack {
                            Button(action: { acceptRequest(request: request) }) {
                                Text("Accept")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            
                            Button(action: { declineRequest(request: request) }) {
                                Text("Decline")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                        }
                    }
                    .listRowBackground(Color.accentColor.opacity(0.1)) // Match invitations list styling
                    .contentShape(Rectangle()) // Prevent row tap interference
                    .padding(.vertical, 8)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Friend Requests")
        .task {
            try? await supabase.updateFriendRequestsList()
        }
    }
    
    private func acceptRequest(request: FriendRequestWithProfile) {
        Task {
            do {
                try await supabase.updateFriendRequestWithProfile(friendRequest: request.friendRequest, status: FriendRequestStatus.accepted)
                
                try await supabase.updateFriendRequestsList()
                
                print("Request accepted: \(request)")
                let toast = ToastValue(
                  message: "Request accepted!"
                )
                presentToast(toast)
            } catch {
                print("Failed to update friend request.")
            }
        }
    }
    
    private func declineRequest(request: FriendRequestWithProfile) {
        Task {
            do {
                try await supabase.updateFriendRequestWithProfile(friendRequest: request.friendRequest, status: FriendRequestStatus.declined)
                
                try await supabase.updateFriendRequestsList()

                print("Request declined: \(request)")
                let toast = ToastValue(
                  message: "Request declined!"
                )
                presentToast(toast)
            } catch {
                print("Failed to update friend request.")
            }
        }
    }
}

#Preview {
    //InboxView()
}
