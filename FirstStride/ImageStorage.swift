import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import UIKit

struct ImageStorageService {
    static let shared = ImageStorageService()
    
    func uploadProfileImage(_ image: UIImage) async throws {
        // 1. Make sure we have a logged-in user
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "ImageStorageService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No logged-in user"]
            )
        }
        
        // 2. Convert UIImage to JPEG data
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "ImageStorageService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"]
            )
        }
        
        // 3. Create a Storage reference: avatars/<uid>.jpg
        let storage = Storage.storage()
        let ref = storage.reference()
            .child("avatars")
            .child("\(uid).jpg")
        
        // 4. Upload data (async/await API)
        _ = try await ref.putDataAsync(data)
        
        // 5. Get download URL
        let url = try await ref.downloadURL()
        
        // 6. Save photoURL into Firestore under users/<uid>
        let db = Firestore.firestore()
        try await db.collection("users")
            .document(uid)
            .setData(
                ["photoURL": url.absoluteString],
                merge: true
            )
    }
}
