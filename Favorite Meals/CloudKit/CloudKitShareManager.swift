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
    /// Generates or fetches a CKShare for a given SwiftData model instance
    func getOrCreateShare(for meal: Meal) async throws -> (CKShare, CKContainer) {
        let nsContext = persistentContainer.viewContext
        
        // 1. Fetch the Core Data NSManagedObject safely using properties common to both stacks
        // We look up the object by its name and notes to get its exact Core Data reference.
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Meal")
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND notes == %@", meal.name, meal.notes)
        fetchRequest.fetchLimit = 1
        
        guard let managedObject = try? nsContext.fetch(fetchRequest).first else {
            throw NSError(
                domain: "CloudKitShareManager",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Object does not exist in underlying Core Data context"]
            )
        }
        
        let shareRecord: CKShare
        let ckContainer: CKContainer
        
        // 2. Query the container to see if a share configuration zone is active
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
        shareRecord.publicPermission = .none // Invited friends strictly see your shared items
        
        return (shareRecord, ckContainer)
    }
}
