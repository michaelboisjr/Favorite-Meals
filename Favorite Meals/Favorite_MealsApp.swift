import SwiftUI
import SwiftData
import CoreData

/// Coordinates the synchronized storage layer between Core Data (for CloudKit Zone Shares) and SwiftData
class CloudDataCoordinator {
    static let shared = CloudDataCoordinator()
    
    let persistentContainer: NSPersistentCloudKitContainer
    let modelContainer: ModelContainer
    
    private init() {
        // 1. Define your SwiftData schema details
        let schema = Schema([Meal.self, Restaurant.self])
        
        // 2. Generate a valid Core Data Managed Object Model directly from your SwiftData types
        guard let managedObjectModel = NSManagedObjectModel.makeManagedObjectModel(for: [Meal.self, Restaurant.self]) else {
            fatalError("Failed to compile a Core Data NSManagedObjectModel from SwiftData classes.")
        }
        
        // 3. Initialize the Core Data container passing the generated runtime model structure
        let container = NSPersistentCloudKitContainer(name: "FavoriteMeals", managedObjectModel: managedObjectModel)
        
        // 4. FIX: Use standard Application Support Directory to establish the SQLite storage path
        let defaultURL = URL.applicationSupportDirectory.appending(path: "default.store")
        let description = NSPersistentStoreDescription(url: defaultURL)
        
        // 5. Explicitly bind the Core Data configuration to use CloudKit
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.FavoriteMealData" // Replace with your real container string
        )
        
        // Requirements for history tracking and remote change notifications
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Assign the manually configured store configurations array back to the container
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved core data stack initialization error: \(error), \(error.userInfo)")
            }
        }
        
        self.persistentContainer = container
        
        // 6. Mount SwiftData directly to the exact same file url initialized by Core Data
        let modelConfiguration = ModelConfiguration(schema: schema, url: defaultURL)
        
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not attach SwiftData layer onto the database storage: \(error)")
        }
    }
}


@main
struct Favorite_MealsApp: App {
    // Reference our unified data engine coordinator
    let coordinator = CloudDataCoordinator.shared
    
    init() {
        seedDataIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(Theme.Colors.background)
        }
        // Attaches SwiftData onto the active UI view hierarchy
        .modelContainer(coordinator.modelContainer)
    }
    
    @MainActor
    private func seedDataIfNeeded() {
        let context = coordinator.modelContainer.mainContext
        let descriptor = FetchDescriptor<Meal>()
        
        guard (try? context.fetchCount(descriptor)) == 0 else { return }
        
        guard let uiImage1 = UIImage(named: "Default-meal1"),
              let imageData1 = uiImage1.jpegData(compressionQuality: 0.8),
              let uiImage2 = UIImage(named: "Default-meal2"),
              let imageData2 = uiImage2.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let restaurant1 = Restaurant(name: "Burger Haven", address: "123 Main St, Boston, MA")
        let restaurant2 = Restaurant(name: "Pasta Palace", address: "456 Oak St, Cambridge, MA")
        
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
