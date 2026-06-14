// File Name: Favorite_MealsApp.swift

import SwiftUI
import SwiftData
import CloudKit

@main
struct Favorite_MealsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let sharedModelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Meal.self,
                Restaurant.self,
            ])
            
            let containerIdentifier = "iCloud.FavoriteMealData"
            let appGroupString = "group.MichaelBoisJrHome.Favorite-Meals"
            
            // Pre-build directory to bypass Sandbox errors
            let fileManager = FileManager.default
            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupString) {
                let appSupportURL = groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
                if !fileManager.fileExists(atPath: appSupportURL.path) {
                    try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
                    print("Successfully pre-created secure App Group directories! 📂")
                }
            }
            
            let unifiedConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupString),
                cloudKitDatabase: .private(containerIdentifier)
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [unifiedConfig]
            )
            self.sharedModelContainer = container
            AppDelegate.sharedModelContainer = container

            // 🎯 FIXED: Remove 'if let' and pass the non-optional URL directly
            CloudKitShareManager.shared.initializeBridge(
                with: unifiedConfig.url,
                containerIdentifier: containerIdentifier
            )

            seedDataIfNeeded(with: container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .background(Theme.Colors.background)
                .onOpenURL { url in
                    print("🔗 App opened via secure system link: \(url.absoluteString)")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CloudKitShareAcceptanceSuccess"),
                        object: url
                    )
                }
        }
        .modelContainer(sharedModelContainer)
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

// MARK: - Core OS Lifecycle Handlers

class AppDelegate: NSObject, UIApplicationDelegate {
    static var sharedModelContainer: ModelContainer?
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self // Force iOS to route events to our custom handler
        return sceneConfig
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    // This catches the invite if the app was completely closed/killed in the background
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let cloudMetadata = connectionOptions.cloudKitShareMetadata {
            acceptCloudKitInvitation(metadata: cloudMetadata)
        }
    }
    
    // This catches the invite if the app was already sitting open in the background
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        acceptCloudKitInvitation(metadata: metadata)
    }
    
    private func acceptCloudKitInvitation(metadata: CKShare.Metadata) {
        print("SceneDelegate intercepted secure iCloud link! Processing handshake... 🔐")
        
        let acceptOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        acceptOperation.qualityOfService = .userInitiated
        
        acceptOperation.acceptSharesResultBlock = { result in
            switch result {
            case .success:
                print("Successfully joined the shared zone! Participant is now ACTIVE. 🎉")
                print("Local main context forced-refreshed successfully.")

                // 🚨 ADD THIS: Broadcast a custom notification to the SwiftUI view hierarchy
                NotificationCenter.default.post(name: NSNotification.Name("CloudKitShareAcceptanceSuccess"), object: nil)
                
                // Tell SwiftData's main context on the main thread to immediately pull updates
                DispatchQueue.main.async {
                    guard let container = AppDelegate.sharedModelContainer else { return }
                    try? container.mainContext.save()
                    print("Local main context forced-refreshed successfully.")
                }
            case .failure(let error):
                print("CloudKit server rejected the invitation handshake: \(error.localizedDescription)")
            }
        }
        
        // Execute the operation against Apple's servers
        CKContainer(identifier: metadata.containerIdentifier).add(acceptOperation)
    }
}
