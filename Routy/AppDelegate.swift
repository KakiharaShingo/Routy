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
    init() {
        FirebaseManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .task {
                    // アプリ起動時に匿名ログインを試行
                    if !AuthService.shared.isAuthenticated {
                        try? await AuthService.shared.signInAnonymously()
                    }
                }
        }
        .modelContainer(for: [Trip.self, Checkpoint.self])
    }
}

