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
    
    let container: ModelContainer
    init() {
        do {
            container = try ModelContainer(for: Meal.self, Restaurant.self)
            seedDataIfNeeded()
        } catch {
            fatalError("Failed to initialize SwiftData container")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(Theme.Colors.background)
        }
        .modelContainer(sharedModelContainer)
    }
    
    
    
    private func seedDataIfNeeded() {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Meal>()
        
        // Check if we have any data
        guard (try? context.fetchCount(descriptor)) == 0 else { return }
        
        // Load your default image from the Asset Catalog
        guard let uiImage = UIImage(named: "Default-meal1"),
              let imageData1 = uiImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        // Load your default image from the Asset Catalog
        guard let uiImage = UIImage(named: "Default-meal2"),
              let imageData2 = uiImage.jpegData(compressionQuality: 0.8) else {
            return
        }
        // Create Seed Data
        let restaurant1 = Restaurant(name: "Burger Haven", address: "123 Main St, Boston, MA")
        let restaurant2 = Restaurant(name: "Pasta Palace", address: "456 Oak St, Cambridge, MA")
        
        // Assign the default imageData to the meals
        let meal1 = Meal(name: "Classic Cheeseburger", rating: 5, notes: "Best in the city!")
        meal1.restaurant = restaurant1
        meal1.imageData = imageData1
        
        let meal2 = Meal(name: "Spaghetti Carbonara", rating: 4, notes: "Authentic taste.")
        meal2.restaurant = restaurant2
        meal2.imageData = imageData2
        
        context.insert(restaurant1)
        context.insert(restaurant2)
        context.insert(meal1)
        context.insert(meal2)
        
        try? context.save()
    }
    
    
}
