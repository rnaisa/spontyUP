//
//  EditProfileView.swift
//  spontyUP
//
//  Created by Pascal on 14.12.2024.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var username: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var originalName: String = ""
    @State private var originalUsername: String = ""
    @State private var isShowingExitConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Name Field
                VStack(alignment: .leading) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Username Field
                VStack(alignment: .leading) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("Enter your username", text: $username)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Profile Image Picker
                VStack(alignment: .leading) {
                    Text("Image")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Button("Choose Profile Image") {
                        selectImage()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Save Changes Button
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                .disabled(username.isEmpty || name.isEmpty)
            }
            .padding()
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleExit) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .confirmationDialog(
                "You have unsaved changes. Do you want to discard your edits or continue editing?",
                isPresented: $isShowingExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    originalName = name
                    originalUsername = username
                    dismiss() // Exit the view
                }
                Button("Continue Editing", role: .cancel) {}
            }
            .interactiveDismissDisabled(!fieldsAreUnchanged()) // Prevent swipe-to-dismiss if there are unsaved changes
            .task {
                try? await supabase.updateCurrentUserProfileVariable()
                loadUserDetails()
            }
        }
    }


    /// Loads the current user's details from the SupabaseHandler
    func loadUserDetails() {
        guard let profile = supabase.currentUserProfile else {
            print("No user profile available")
            return
        }
        name = profile.fullName ?? ""
        username = profile.username
        originalName = name
        originalUsername = username
    }
    
    private func fieldsAreUnchanged() -> Bool {
        return name == originalName && username == originalUsername
    }

    /// Handles the exit action, checking for unsaved changes
    func handleExit() {
        if !fieldsAreUnchanged() {
            isShowingExitConfirmation = true
        } else {
            dismiss()
        }
    }

    /// Mocked photo picker
    func selectImage() {
        print("Image picker not implemented yet.")
    }

    /// Saves the updated user details
    func saveChanges() {
        Task {
            do {
                // Update the user profile in the database
                try await supabase.updateCurrentUserProfile(
                    username: username,
                    fullName: name
                )

                // Update original values to prevent discard dialog
                originalName = name
                originalUsername = username

                // Dismiss the view
                dismiss()
                print("Profile updated successfully.")
            } catch {
                print("Failed to update profile: \(error)")
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environment(SupabaseHandler.shared)
}
