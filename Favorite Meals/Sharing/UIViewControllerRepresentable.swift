//file name: UIViewControllerRepresntable

import SwiftUI
import CloudKit

struct CloudShareView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.delegate = context.coordinator // 👈 Enforces live participant updates        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite, .allowReadOnly]
        sharingController.delegate = context.coordinator
        return sharingController
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        
        // MARK: - Required Protocol Methods
        
        // 1. Required: Provides the title string shown at the top of the system share sheet
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Shared Favorite Meals"
        }
        
        // 2. Required: Called if an error or user action causes the save operation to fail
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed saving share: \(error.localizedDescription)")
        }
        
        // MARK: - Optional Lifecycle Methods
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Successfully saved data share.")
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("User stopped sharing this data zone.")
        }
    }
}
