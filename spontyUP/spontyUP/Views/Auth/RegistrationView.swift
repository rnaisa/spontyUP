//
//  ContentView.swift
//  spontyUP
//
//  Created by Pascal on 24.11.2024.
//

import SwiftUI
import Supabase

struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var result: Result<Void, Error>?

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // App Icon and Title
                VStack {
                    Image("spontyUP_logo_image") // App icon from Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 5)

                    Text("Create Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                }
                
                // Input Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    TextField("Full Name", text: $fullName)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                // Register Button
                Button(action: registerUserProfileTapped) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                // Loading Indicator
                if isLoading {
                    ProgressView("Processing...")
                        .padding()
                }

                // Success/Error Messages
                if let result {
                    VStack {
                        switch result {
                        case .success:
                            Text("Account created successfully!")
                                .foregroundColor(.green)
                        case .failure(let error):
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Handles user registration
    func registerUserProfileTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await supabase.signUp(email: email, password: password)
                try await supabase.registerCurrentUserProfile(
                    username: username,
                    fullName: fullName
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}

#Preview {
    RegistrationView()
        .environment(SupabaseHandler.shared)
        .environment(UserSettings.shared)
}
