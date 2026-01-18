//
//  spontyUPApp.swift
//  spontyUP
//
//  Created by Pascal on 24.11.2024.
//

import SwiftUI
import Toasts

@main
struct spontyUPApp: App {
    @State private var supabase = SupabaseHandler.shared
    @State private var userSettings = UserSettings.shared
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(supabase)
                .environment(userSettings)
                .installToast(position: .bottom)
                .accentColor(Color("AccentColor"))
        }
    }
}
