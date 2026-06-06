//
//  Favorite_MealsApp.swift
//  Favorite Meals
//
//  Created by Michael Bois on 6/3/26.
//

import SwiftUI
import SwiftData

@main
struct Favorite_MealsApp: App {
    var sharedModelContainer: ModelContainer = {
        // 1. Include ALL your models here
        let schema = Schema([
            Meal.self,
            Restaurant.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(Theme.Colors.background)
        }
        .modelContainer(sharedModelContainer)
    }
}
