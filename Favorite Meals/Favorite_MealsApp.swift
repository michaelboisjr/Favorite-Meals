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
    // Maintain a single container instance for the entire lifecycle
    let sharedModelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Meal.self,
                Restaurant.self,
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            // Initialize our unified container
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.sharedModelContainer = container
            
            // Run the seed check immediately using this container
            seedDataIfNeeded(with: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(Theme.Colors.background)
        }
        .modelContainer(sharedModelContainer) // Inject the correct container
    }
    
    private func seedDataIfNeeded(with container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Meal>()
        
        // Only seed if the database is currently empty
        guard (try? context.fetchCount(descriptor)) == 0 else { return }
        
        // Safely extract both asset photos
        guard let uiImage1 = UIImage(named: "Default-meal1"),
              let resizedImage1 = uiImage1.resized(toWidth: 800),
              let imageData1 = resizedImage1.jpegData(compressionQuality: 0.8),
              let uiImage2 = UIImage(named: "Default-meal2"),
              let resizedImage2 = uiImage2.resized(toWidth: 800),
              let imageData2 = resizedImage2.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        // Create Seed Data
        let restaurant1 = Restaurant(name: "Burger Haven", address: "123 Main St, Boston, MA")
        let restaurant2 = Restaurant(name: "Pasta Palace", address: "456 Oak St, Cambridge, MA")
        
        let meal1 = Meal(name: "Classic Cheeseburger", rating: 5, notes: "Best in the city!", restaurant: restaurant1)
        meal1.imageData = imageData1
        
        let meal2 = Meal(name: "Spaghetti Carbonara", rating: 4, notes: "Authentic taste.", restaurant: restaurant2)
        meal2.imageData = imageData2
        
        // Insert parents; cascade delete handle rule inserts child relationships automatically
        context.insert(restaurant1)
        context.insert(restaurant2)
        context.insert(meal1)
        context.insert(meal2)
        
        try? context.save()
    }
}
