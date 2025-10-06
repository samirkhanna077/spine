//
//  UserModel.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/2/25.
//

import SwiftUI
import FirebaseFirestore

struct UserModel: Identifiable, Decodable {
    @DocumentID var id: String?
    var username: String
    var dateCreated: Date
    var timezone: String
    var profileImageID: String?
}


struct OtherUserModel: Identifiable, Decodable {
    var id: String
    var username: String
    var dateCreated: String
}
