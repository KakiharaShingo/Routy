//
//  TravelLogApp.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

@main
struct TravelLogApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Trip.self, Checkpoint.self])
    }
}

