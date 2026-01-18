//
//  ContentView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 02.12.2024.
//

import SwiftUI
 
struct ContentView: View {
    var body: some View {
        TabView {
            FeedView()
            .tabItem {
                    Image(systemName: "house.fill")
                    Text("Feed")
                }
            InboxView()
            .tabItem {
                    Image(systemName: "tray.fill")
                    Text("Inbox")
                }
            ManageEventView()
                        .tabItem {
                                Image(systemName: "plus.square")
                                Text("Events")
                            }
            FriendsAndGroupsView()
            .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Friends")
                }
            ProfileView()
            .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(SupabaseHandler.shared)
        .environment(UserSettings.shared)
}
