//
//  AppView.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 02.12.2024.
//

import SwiftUI
import Supabase

struct AppView: View {
    @State var isAuthenticated = false
    
    @Environment(SupabaseHandler.self) private var supabase
    @Environment(UserSettings.self) private var userSettings
    

      var body: some View {
        @Bindable var userSettings = userSettings
        Group {
            if isAuthenticated && supabase.isRegistered {
            ContentView()
          } else if !isAuthenticated {
            AuthView()
          } else {
            RegistrationView()
          }
        }
        .task {
          for await state in supabase.auth.authStateChanges {
            if [.initialSession, .signedIn, .signedOut].contains(state.event) {
              isAuthenticated = state.session != nil
                do {
                    try await  supabase.updateRegistrationStatus()
                } catch {
                    print("Registration Check failed.")
                }
                
            }
          }
            
        }
      }
}

#Preview {
    AppView()
        .environment(SupabaseHandler.shared)
        .environment(UserSettings.shared)
}
