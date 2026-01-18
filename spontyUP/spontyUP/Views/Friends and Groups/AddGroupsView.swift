//
//  AddGroupsView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 09.12.2024.
//

import SwiftUI

struct AddGroupsView: View {
    @State private var groupName: String = ""
    @State private var isCreating: Bool = false
    @State private var groupMembers: [FriendshipWithProfile] = []
    @State private var result: Result<Void, Error>?
    
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group Name", text: $groupName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section("Members") {
                    NavigationLink(destination: SelectFriendsView(selectedFriends: $groupMembers)) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Member")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    ForEach(groupMembers, id: \.id) { member in
                        Text(member.friendship.friendUsername)
                    }
                }
                
                // Create Button
                Button(action: createGroup) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text("Create Group")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(groupName.isEmpty || isCreating)
                
                if let result {
                    Section {
                        switch result {
                        case .success:
                            Text("Group created successfully.")
                                .foregroundColor(.green)
                        case .failure(let error):
                            Text("Failed: \(error.localizedDescription)")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Create New Group")
        }
    }
    
    private func createGroup() {
        Task {
            isCreating = true
            defer { isCreating = false }
            do {
                // Create group in Supabase
                let returnedGroup = try await supabase.createAndReturnGroup(name: groupName)
                
                // Map and send group member data
                let members = groupMembers.map {
                    CreateGroupMemberParams(groupId: returnedGroup.id, friendId: $0.friendship.friendId, friendshipId: $0.friendship.friendshipId)
                }
                try await supabase.createGroupMembers(members: members)
                
                // Mark as success
                result = .success(())
                
                // Reset state and dismiss view
                groupName = ""
                groupMembers = []
                
                // Delay dismissal to show success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } catch {
                result = .failure(error)
            }
        }
    }
}


#Preview {
    AddGroupsView()
}
