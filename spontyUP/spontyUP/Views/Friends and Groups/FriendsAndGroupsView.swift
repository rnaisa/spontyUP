//
//  FriendsAndGroupsView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 04.12.2024.
//

import SwiftUI

struct FriendsAndGroupsView: View {
    @State private var selectedSubTab: FriendsGroupsSubTab = .friends

    @Environment(SupabaseHandler.self) private var supabase

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
                        ForEach(FriendsGroupsSubTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .tint(Color.accentColor)
                    .padding(.horizontal)
                }
                .frame(height: 32) // Optional: Ensure the container height is consistent with default Picker height

                GeometryReader { geometry in
                    ZStack {
                        if selectedSubTab == .friends {
                            FriendsListView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.move(edge: .leading)) // Slide in from the left
                        } else if selectedSubTab == .groups {
                            GroupsListView()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .transition(.move(edge: .trailing)) // Slide in from the right
                        }
                    }
                    .animation(.easeInOut, value: selectedSubTab) // Smooth animation
                }
                .clipped() // Prevent overflow
            }
            .navigationTitle("Friends")
        }
    }
}

enum FriendsGroupsSubTab: String, CaseIterable {
    case friends = "Friends"
    case groups = "Groups"
}

struct FriendsListView: View {
    @Environment(SupabaseHandler.self) private var supabase

    var body: some View {
        NavigationStack {
            List {
                // Add Friends Section
                Section(header: Text("Actions")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    NavigationLink(
                        destination: AddFriendsView()
                    ) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add Friend")
                        }
                    }
                }

                // Friends List Section
                Section(header: Text("Your Friends")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    ForEach(supabase.friendsList) { friend in
                        NavigationLink(destination: FriendDetailView(friend: friend)) {
                            Text("\(friend.profile.username)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Friends List")
            .task {
                try? await supabase.updateFriendsList()
            }
        }
    }
}

struct GroupsListView: View {
    @Environment(SupabaseHandler.self) private var supabase
    @State private var showCreateGroupView: Bool = false

    var body: some View {

        NavigationStack {
            List {
                Section(header: Text("Actions")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    Button(action: {
                        showCreateGroupView = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor) // Icon in accent color
                            Text("Create Group")
                                .foregroundColor(.primary) // Text in default primary color - stated explicitly because is in button
                        }
                    }
                    .sheet(isPresented: $showCreateGroupView, onDismiss: handleDismiss) {
                        AddGroupsView()
                    }
                }


                // Friends List Section
                Section(header: Text("Your Groups")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .bold()
                    .textCase(nil) // Preserve case sensitivity
                ) {
                    ForEach(supabase.groupsList) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            Text("\(group.name)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Groups List")
            .task {
                await updateGroups()
            }
        }
    }
    
    private func updateGroups() async {
        do {
            try await supabase.updateGroupsList()
        } catch {
            print("error updating groups")
        }
    }
    
    private func handleDismiss() {
        Task {
            await updateGroups()
        }
    }
}

#Preview {
    FriendsAndGroupsView()
        .environment(SupabaseHandler.shared)
}
