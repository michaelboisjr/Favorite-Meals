import SwiftUI
import CloudKit
import UIKit

struct CloudKitShareRepresentable: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        // Initialize the native iOS cloud sharing view controller
        let controller = UICloudSharingController(share: share, container: container)
        
        // Block friends from editing your meals list
        controller.availablePermissions = [.allowReadOnly]
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // The required UIKit coordinator to manage lifecycle calls
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ CloudKit failed to save the meal share record: \(error.localizedDescription)")
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ CloudKit share initiated and securely synced successfully.")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("🛑 User stopped sharing this data feed with their friends.")
        }
        
        // Returns the thumbnail title shown to friends inside Apple Messages / Mail invites
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Shared Meals Feed"
        }
    }
}
