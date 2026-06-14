//file name: ModleContext+CloudKit

import Foundation
import SwiftData
import CloudKit
import CoreData

extension ModelContext {
    /// Generates a clean, unique share record mapped specifically to this model state
    @MainActor
    func fetchOrCreateShare(for model: any PersistentModel) async throws -> (CKShare, CKContainer) {
        let containerIdentifier = "iCloud.FavoriteMealData"
        let cloudKitContainer = CKContainer(identifier: containerIdentifier)
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        
        // Use the system zone where SwiftData routes our elements
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        
        // 🚨 THE FIX: Create a unique record name based on the specific model's stable identifier.
        // This stops different share attempts or multiple people from deadlocking the same share record!
        let uniqueShareName = "share_\(model.persistentModelID.hashValue)"
        let shareRecordID = CKRecord.ID(recordName: uniqueShareName, zoneID: zoneID)
        
        // 1. Check if a clean share already exists for this specific model item
        do {
            let existingShareRecord = try await privateDatabase.record(for: shareRecordID)
            if let existingShare = existingShareRecord as? CKShare {
                print("Found active dedicated share container! 🎯")
                return (existingShare, cloudKitContainer)
            }
        } catch {
            print("Creating pristine cryptographic keys for this share action...")
        }
        
        // 2. Build a fresh, clean share record explicitly tied to this zone boundary
        let newShare = CKShare(recordZoneID: zoneID)
        newShare[CKShare.SystemFieldKey.title] = "Shared Favorite Restaurant Details" as CKRecordValue
        newShare[CKShare.SystemFieldKey.shareType] = "com.apple.FavoriteMeals.mealShare" as CKRecordValue
        
        // Explicitly ensure the local context changes are saved before network dispatching
        try? self.save()
        
        // 3. Register the clean share to Apple's cloud servers
        let operation = CKModifyRecordsOperation(recordsToSave: [newShare], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("Successfully registered unique cloud share anchor! 🚀")
                    continuation.resume(returning: (newShare, cloudKitContainer))
                case .failure(let error):
                    print("CloudKit rejected share creation: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            privateDatabase.add(operation)
        }
    }
}
