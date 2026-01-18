//
//  AddGroupsToView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 15.12.2024.
//

import SwiftUI

struct AddGroupsToView: View {
    @State private var searchText: String = ""
    @State var selectedGroups: [FriendGroup] = []
    @State private var availableGroups: [FriendGroup] = []

    let existingGroups: [FriendGroup]  // Members already in the group
    let onSelectionCompleted: ([FriendGroup]) -> Void

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss  // Add dismiss environment

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(filteredGroups, id: \.id) { group in
                        HStack {
                            Text(group.name)
                            Spacer()
                            Button(action: {
                                toggleSelection(for: group)
                            }) {
                                Image(
                                    systemName: isSelected(group)
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .foregroundColor(
                                    isSelected(group) ? .accentColor : .gray)
                            }
                        }
                        .padding()
                        .background(
                            isSelected(group)
                                ? Color.accentColor.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
                .navigationTitle("Select Groups")
                .searchable(text: $searchText, prompt: "Search Groups")
                .onAppear {
                    loadAvailableGroups()
                }

                Button("Confirm Selection") {
                    onSelectionCompleted(selectedGroups)
                    dismiss()  // Dismiss the view
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(selectedGroups.isEmpty)  // Disable if no friends selected
            }
        }
    }

    // Filter friends to exclude existing members
    private var filteredGroups: [FriendGroup] {
        availableGroups
            .filter { group in
                !existingGroups.contains(where: {
                    $0.id == group.id
                })
                    && (searchText.isEmpty
                        || group.name
                            .localizedCaseInsensitiveContains(searchText))
            }
    }

    private func isSelected(_ group: FriendGroup) -> Bool {
        selectedGroups.contains(where: {
            $0.id == group.id
        })
    }

    private func toggleSelection(for group: FriendGroup) {
        if let index = selectedGroups.firstIndex(where: {
            $0.id == group.id
        }) {
            selectedGroups.remove(at: index)  // Deselect
        } else {
            selectedGroups.append(group)  // Select
        }
    }

    private func loadAvailableGroups() {
        // Replace this with actual fetching logic
        availableGroups = supabase.groupsList
    }
}

#Preview {
    //AddGroupsToView()
}
