import Foundation
import SwiftData
import CloudKit
import CoreData

extension ModelContext {
    /// Retrieves an existing CKShare or creates and registers a new one on the server
    @MainActor
    func fetchOrCreateShare(for model: any PersistentModel) async throws -> (CKShare, CKContainer) {
        let containerIdentifier = "iCloud.FavoriteMealData"
        let cloudKitContainer = CKContainer(identifier: containerIdentifier)
        
        guard let _ = self.container.configurations.first else {
            throw NSError(domain: "SwiftDataShareError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve ModelConfiguration settings."])
        }
        
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let shareRecordID = CKRecord.ID(recordName: "cloudKitShare", zoneID: zoneID)
        
        // 1. Try to fetch an existing share from the server
        do {
            let existingShareRecord = try await privateDatabase.record(for: shareRecordID)
            if let existingShare = existingShareRecord as? CKShare {
                print("Found existing cloud share on server! 🎉")
                return (existingShare, cloudKitContainer)
            }
        } catch {
            print("No existing cloud share zone on server. Creating and registering a new one...")
        }
        
        // 2. If it doesn't exist, build the new CKShare locally
        let newShare = CKShare(recordZoneID: zoneID)
        newShare[CKShare.SystemFieldKey.title] = "Shared Favorite Restaurant Details" as CKRecordValue
        newShare[CKShare.SystemFieldKey.shareType] = "com.apple.FavoriteMeals.mealShare" as CKRecordValue
        
        // 3. CRITICAL FIX: Explicitly save the new Share record to the CloudKit Server
        // We use a modify operation to push the record up immediately
        let operation = CKModifyRecordsOperation(recordsToSave: [newShare], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("Successfully saved new CKShare record to iCloud servers! 🚀")
                    continuation.resume(returning: (newShare, cloudKitContainer))
                case .failure(let error):
                    print("Failed to save CKShare to server: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            // Execute the push to Apple's sandbox servers
            privateDatabase.add(operation)
        }
    }
}
