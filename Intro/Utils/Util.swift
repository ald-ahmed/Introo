import UIKit
import FirebaseStorage

extension ViewController {
    
    
    func uploadToStorage(dataURL: URL, sessionID: String) {
        
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        
        // Create a storage reference from our storage service
        let storageRef = storage.reference().child(UUID().uuidString+".m4a")
        
        // Data in memory
        let data = try? Data(contentsOf: dataURL)
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = storageRef.putData(data!, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            
            // You can also access to download URL after upload.
            storageRef.downloadURL { (url, error) in
                
                if let error = error {
                    print("Error getting download URL: \(error)")
                    return
                }
                
                print ("size is: ", size)
                
                let stringURL = (url?.absoluteString ?? "")
                
                let sessionRef =  self.ref.child("sessions").child(sessionID)
                sessionRef.child( "audio"+String(self.imIFirstOrSecondParticipant) ).setValue(stringURL)
                
            }
            
        }
        
    }
    
}
