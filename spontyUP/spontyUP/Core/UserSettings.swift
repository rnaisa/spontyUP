//
//  UserSettings.swift
//  spontyUP
//
//  Created by HSLU-N0004887 on 02.12.2024.
//

//
//  UserSettings.swift
//  Levels
//
//  Created by Matthias Felix on 29.09.2023.
//

import Foundation
import SwiftUI

@Observable
class UserSettings {
    static let shared = UserSettings()

    private init() {}

    var alwaysUseDarkMode = false
}
