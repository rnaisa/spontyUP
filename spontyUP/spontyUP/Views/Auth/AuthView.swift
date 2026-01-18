//
//  AuthView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 01.12.2024.
//

import Supabase
import SwiftUI

struct AuthView: View {
    @State var email = ""
    @State var password = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?

    @Environment(SupabaseHandler.self) private var supabase
    @Environment(UserSettings.self) private var userSettings

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo or Placeholder
                VStack {
                    Image("spontyUP_logo_image") // App icon from Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                        .padding(.top, 16)
                    
                    Text("Welcome to spontyUP!")
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
                }
                .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: signInButtonTapped) {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: RegistrationView()) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Loading Indicator (fun fact the loading spinner thingy is called a throbber - The more you know."
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                }

                // Success/Error Message
                if let result {
                    VStack {
                        switch result {
                        case .success:
                            Text("Signed in successfully.")
                                .foregroundColor(.green)
                        case .failure(let error):
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true) // Hide the default navigation title
        }
    }

    func signInButtonTapped() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await supabase.signIn(email: email, password: password)
                result = .success(())
            } catch {
                result = .failure(error)
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(SupabaseHandler.shared)
        .environment(UserSettings.shared)
}
