//File Name: CloudKitShareManager

import SwiftData
import CoreData
import CloudKit
import UIKit

@MainActor
final class CloudKitShareManager: NSObject {
    static let shared = CloudKitShareManager()
    
    private var persistentContainer: NSPersistentCloudKitContainer?
    private var isInitialized = false
    
    private override init() { super.init() }
    
    /// Coordinates the bridge by pointing Core Data to the exact SQLite file SwiftData is using.
    func initializeBridge(with storeURL: URL, containerIdentifier: String) {
        guard !isInitialized else { return }
        
        // 1. Configure the store description to match SwiftData's local file
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.configuration = "Default"
        
        // 2. Attach CloudKit options for native Zone Sharing
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        storeDescription.cloudKitContainerOptions = cloudKitOptions
        
        // 3. Enforce tracking options required for cloud syncing
        storeDescription.setOption(true as NSNumber, forKey: NSSQLitePragmasOption)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // 4. Instantiate the container using an ephemeral name
        let container = NSPersistentCloudKitContainer(name: "SwiftDataSharingContainer")
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("⚠️ Core Data Bridge failed to load store: \(error.localizedDescription)")
            } else {
                self.isInitialized = true
                print("✅ Core Data Sharing Bridge successfully initialized.")
            }
        }
        
        self.persistentContainer = container
    }
    
    /// Fetches the backing managed object and presents the native UICloudSharingController
    // Inside CloudKitShareManager.swift

    func presentShareSheet(for recordID: UUID, entityName: String, from viewController: UIViewController) {
        guard let container = persistentContainer else {
            print("⚠️ Bridge container not ready.")
            return
        }
        
        let context = container.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        // ✅ FIXED: Look up using the explicit "uuid" field
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", recordID as CVarArg)
        
        guard let managedObject = try? context.fetch(fetchRequest).first else {
            print("⚠️ Could not locate the matching database record for Core Data tracking.")
            return
        }
        
        let sharingController = UICloudSharingController { [weak self] (_, completion) in
            container.share([managedObject], to: nil) { _, share, ckContainer, error in
                completion(share, ckContainer, error)
            }
        }
        
        sharingController.delegate = self
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        
        viewController.present(sharingController, animated: true)
    }
}

// MARK: - UICloudSharingControllerDelegate
extension CloudKitShareManager: UICloudSharingControllerDelegate {
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("💾 CloudKit Share saved and updated via native Core Data tracking.")
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("❌ CloudKit Share failed to update: \(error.localizedDescription)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "Shared Content"
    }
}
