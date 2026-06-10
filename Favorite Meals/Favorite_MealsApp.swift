import SwiftUI
import SwiftData
import CoreData
import CloudKit

/// Coordinates the synchronized storage layer between Core Data (for CloudKit Zone Shares) and SwiftData
@MainActor
class CloudDataCoordinator {
    static let shared = CloudDataCoordinator()
    
    let persistentContainer: NSPersistentCloudKitContainer
    let modelContainer: ModelContainer
    
    private init() {
        let schema = Schema([Meal.self, Restaurant.self])
        
        // 1. Create a pristine model instance from SwiftData definitions
        guard let managedObjectModel = NSManagedObjectModel.makeManagedObjectModel(for: [Meal.self, Restaurant.self]) else {
            fatalError("Failed to compile Model.")
        }
        
        let defaultURL = URL.applicationSupportDirectory.appending(path: "default.store")
        let sharedURL = URL.applicationSupportDirectory.appending(path: "shared.store")
        
        // 2. Configure Core Data Private Store Descriptions
        let privateDescription = NSPersistentStoreDescription(url: defaultURL)
        privateDescription.configuration = "Default"
        privateDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.FavoriteMealData")
        privateDescription.cloudKitContainerOptions?.databaseScope = .private
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // 3. Configure Core Data Shared Store Descriptions
        let sharedDescription = NSPersistentStoreDescription(url: sharedURL)
        sharedDescription.configuration = "PF_CloudKitShare"
        sharedDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.FavoriteMealData")
        sharedDescription.cloudKitContainerOptions?.databaseScope = .shared
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // 4. Fire up the Core Data stack first
        let container = NSPersistentCloudKitContainer(name: "FavoriteMeals", managedObjectModel: managedObjectModel)
        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ Core Data store load failed: \(error.localizedDescription)")
            }
        }
        self.persistentContainer = container
        
        // 5. Mount SwiftData locally to the exact same file path
        // CRITICAL: We DO NOT pass CloudKit options to this ModelConfiguration.
        // Core Data is handling the cloud sync; SwiftData is just an elegant window to the local database file.
        let modelConfiguration = ModelConfiguration(schema: schema, url: defaultURL)
        
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not attach SwiftData: \(error)")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, userActivityWillSave userActivity: NSUserActivity) {}
    
    // This is the magic hook iOS calls when a user opens an iCloud share link
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        Task {
            let container = CKContainer(identifier: metadata.containerIdentifier)
            let acceptOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
            
            acceptOperation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    print("✅ Successfully accepted and attached friend's shared meal feed!")
                case .failure(let error):
                    print("❌ Failed to accept CloudKit share: \(error.localizedDescription)")
                }
            }
            
            container.add(acceptOperation)
        }
    }
}


@main
struct Favorite_MealsApp: App {
    // Reference our unified data engine coordinator
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
              let resizedImage1 = uiImage1.resized(toWidth: 800),
              let imageData1 = resizedImage1.jpegData(compressionQuality: 0.8),
              let uiImage2 = UIImage(named: "Default-meal2"),
              let resizedImage2 = uiImage2.resized(toWidth: 800),
              let imageData2 = resizedImage2.jpegData(compressionQuality: 0.8) else {
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
        
        do {
            try context.save() // 👈 Force SwiftData to write to the physical file immediately
            print("✅ Seed data successfully written to disk.")
        } catch {
            print("❌ Failed to save seed data: \(error)")
        }
    }
}
