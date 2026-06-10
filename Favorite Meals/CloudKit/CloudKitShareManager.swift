import Foundation
import SwiftData
import CloudKit
import CoreData

@MainActor
class CloudKitShareManager {
    let modelContext: ModelContext
    let persistentContainer: NSPersistentCloudKitContainer
    
    // Pass both structural references directly during setup
    init(modelContext: ModelContext, persistentContainer: NSPersistentCloudKitContainer) {
        self.modelContext = modelContext
        self.persistentContainer = persistentContainer
    }
    
    /// Generates or fetches a CKShare for a given SwiftData model instance
    func getOrCreateShare(for meal: Meal) async throws -> (CKShare, CKContainer) {
        let nsContext = persistentContainer.viewContext
        
        // 1. Force Core Data to clear its internal memory snapshots
        nsContext.reset()
        
        // 2. Extract the clean primary key identifier directly from the SwiftData model ID
        let swiftDataID = meal.persistentModelID
        
        // 3. Match it against Core Data's active SQLite persistent store assignment
        guard let coordinator = nsContext.persistentStoreCoordinator,
              let firstStore = coordinator.persistentStores.first else {
            throw NSError(domain: "CloudKitShareManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active persistent stores found."])
        }
        
        // 4. Extract the unique primary key suffix via JSON Serialization
        guard let data = try? JSONEncoder().encode(swiftDataID),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let implementation = json["implementation"] as? [String: Any],
              let primaryKey = implementation["primaryKey"] as? String else {
            throw NSError(domain: "CloudKitShareManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to read structural identity key via JSON mapping."])
        }
        
        // 5. Build the clean x-coredata URI manually using Core Data's standard format (Bypassing module names!)
        // Format: x-coredata://[StoreID]/[EntityName]/[PrimaryKey]
        let cleanURIString = "x-coredata:///\(firstStore.identifier)/Meal/\(primaryKey)"
        guard let cleanURL = URL(string: cleanURIString),
              let managedObjectID = coordinator.managedObjectID(forURIRepresentation: cleanURL) else {
            throw NSError(domain: "CloudKitShareManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to locate matching Core Data entity layout from clean identifier URL."])
        }
        
        // 6. Pull the record object safely from disk
        guard let managedObject = try? nsContext.existingObject(with: managedObjectID) else {
            throw NSError(domain: "CloudKitShareManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Object does not exist in underlying Core Data context"])
        }
        
        let shareRecord: CKShare
        let ckContainer: CKContainer
        
        // 7. Query the container to see if a share configuration zone is active
        if let shares = try? persistentContainer.fetchShares(matching: [managedObject.objectID]),
           let (_, existingShare) = shares.first {
            shareRecord = existingShare
            
            if let options = persistentContainer.persistentStoreDescriptions.first?.cloudKitContainerOptions {
                let identifier = options.containerIdentifier
                ckContainer = CKContainer(identifier: identifier)
            } else {
                ckContainer = CKContainer.default()
            }
        } else {
            // Generate a secure managed sharing block using Checked Continuation primitives
            let result: (CKShare, CKContainer) = try await withCheckedThrowingContinuation { continuation in
                persistentContainer.share([managedObject], to: nil) { _, share, container, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let share = share, let container = container {
                        continuation.resume(returning: (share, container))
                    } else {
                        let unknownError = NSError(
                            domain: "CloudKitShareManager",
                            code: 5,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to allocate a target CKShare block."]
                        )
                        continuation.resume(throwing: unknownError)
                    }
                }
            }
            shareRecord = result.0
            ckContainer = result.1
        }
        
        // Structural validation details for CloudKit invitations
        shareRecord[CKShare.SystemFieldKey.title] = "Shared Meals Feed" as CKRecordValue
        shareRecord.publicPermission = .none
        
        return (shareRecord, ckContainer)
    }
    
    // MARK: - Core Data Bridging Private Helper
    /// Deep-inspects a SwiftData PersistentIdentifier structure via Codable and strips module names from the URI
    private func extractURI(from identifier: PersistentIdentifier) -> URL? {
        guard let data = try? JSONEncoder().encode(identifier),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let implementation = json["implementation"] as? [String: Any],
              var uriString = implementation["uriRepresentation"] as? String else {
            return nil
        }
        
        // 🔥 THE FIX: If the URI contains a namespaced entity format (e.g., "Favorite_Meals.Meal"),
        // strip out the target prefix so Core Data can match it against its clean "Meal" entity.
        if let range = uriString.range(of: "x-coredata:///") {
            let pathStart = range.upperBound
            let remainingPath = uriString[pathStart...]
            
            // Find if there is a dot separator signifying a Swift module prefix
            if let dotIndex = remainingPath.firstIndex(of: ".") {
                let entityStart = remainingPath.index(after: dotIndex)
                let cleanedPath = remainingPath[entityStart...]
                uriString = "x-coredata:///\(cleanedPath)"
            }
        }
        
        return URL(string: uriString)
    }
}
