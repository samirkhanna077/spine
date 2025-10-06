//
//  UserViewModel.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/2/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// TODO: add listener to core data fields

@MainActor
class UserViewModel: ObservableObject {
    let imageManager = ImageManager()
    
    @Published var userModel: UserModel?
    @Published var profilePicture: UIImage? = nil // default empty
    @Published var isLoggedIn: Bool = false // default false
    @Published var dataFetched: Bool = false
        
    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        print("User is logged in? \(self.isLoggedIn)")
    }
    
    func fetchUserData() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Failed to fetch user ID...")
            return
        }
        
        do {
            let document = try await database.collection("users").document(userID).getDocument()
            let username = document.get("username") as? String ?? ""
            let timezone = document.get("timezone") as? String ?? ""
            let dateCreated = document.get("dateCreated") as? Date ?? Date()
            let profileImageID = document.get("profileImageID") as? String ?? ""
            
            let user = UserModel(
                id: document.documentID,
                username: username,
                dateCreated: dateCreated,
                timezone: timezone,
                profileImageID: profileImageID
            )
            
            DispatchQueue.main.async {
                self.userModel = user
                self.dataFetched = true
            }
            print("Data: \(user)")

            // attempt to fetch profile image
            if let imageID = user.profileImageID, !imageID.isEmpty {
                print("Fetching profile image for \(userID)...")
                self.imageManager.get(imageID: imageID, completion: { profileImage in
                    if let image = profileImage {
                        self.profilePicture = image
                    }
                })
            }
            
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.dataFetched = false
                self.isLoggedIn = false
            }
        }
    }

}



class OtherUserViewModel: ObservableObject {
    @Published var otherUserModel: OtherUserModel?
    @Published var profilePicture: UIImage? = nil
    
    init(otherUserID: String? = nil) {
        // let otherUser: OtherUserModel = fetchOtherUserData()
        // handle optionals
        // fetch pfp
    }
}
