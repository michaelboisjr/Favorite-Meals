import Foundation
import SwiftData
import CloudKit
import CoreData

extension ModelContext {
    /// Retrieves an existing CKShare or creates a new one for a specific SwiftData model instance
    @MainActor
    func fetchOrCreateShare(for model: any PersistentModel) async throws -> (CKShare, CKContainer) {
        // 1. Establish connection to your targeted iCloud Container
        let containerIdentifier = "iCloud.FavoriteMealData"
        let cloudKitContainer = CKContainer(identifier: containerIdentifier)
        
        // 2. Fetch the native persistent CloudKit container directly via the ModelContainer configurations
        // This avoids tapping into private persistentStoreCoordinator properties
        guard let persistentContainer = self.container.configurations.first else {
            throw NSError(domain: "SwiftDataShareError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve ModelConfiguration container settings."])
        }
        
        // 3. Define the dedicated Core Data CloudKit Zone ID where shared objects live
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        
        // 4. Try fetching an existing share relationship bundle from the private CloudKit Database
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        
        do {
            // FIX: Replaced CKRecord.Name.zoneShare with the correct literal system key string
            let shareRecordID = CKRecord.ID(recordName: "cloudKitShare", zoneID: zoneID)
            let existingShareRecord = try await privateDatabase.record(for: shareRecordID)
            
            if let existingShare = existingShareRecord as? CKShare {
                return (existingShare, cloudKitContainer)
            }
        } catch {
            // Error code 11 is CKError.unknownItem (Zone/Share doesn't exist yet on iCloud), which is expected on first run.
            print("No existing cloud share zone found, initializing a fresh one...")
        }
        
        // 5. Fallback: Initialize a brand new native CKShare instance
        let newShare = CKShare(recordZoneID: zoneID)
        newShare[CKShare.SystemFieldKey.title] = "Shared Favorite Restaurant Details" as CKRecordValue
        newShare[CKShare.SystemFieldKey.shareType] = "com.apple.FavoriteMeals.mealShare" as CKRecordValue
        
        return (newShare, cloudKitContainer)
    }
}
