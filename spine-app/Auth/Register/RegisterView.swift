//
//  RegisterView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/17/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging


public struct RegisterView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    // UI FLOW
    @State var offset: CGFloat = 0
    @State var loading: Bool = false
    @State var registerStep = 1
    
    // ALERTS
    @State var alertMessage: String = ""
    @State var showAlert: Bool = false
    
    // FOCUS FIELDS
    enum Field { case username }
    @FocusState var focusedField: Field?
    
    // ACTIVE VARS
    @State var username: String = UserDefaults.standard.string(forKey: "username") ?? ""
    
    public var body: some View {
        ZStack {
            VStack(spacing: 50) {
                Spacer()
                
                HStack(spacing: screenWidth) {
                    Username(username: self.$username, focused: self.$focusedField)
                        .frame(width: screenWidth)
                }
                .offset(x: self.offset)
                .padding()
                
                Spacer()
                
                Button(action: {
                    Task {
                        await submit { success in
                            if success {
                                registerStep += 1
                                print("Success!")
                            }
                        }
                    }
                }) {
                    if loading {
                        ZStack {
                            PrimaryButton(text: "")
                            ProgressView()
                        }
                    } else { PrimaryButton(text: "SUBMIT") }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear() {
            DispatchQueue.main.async { self.focusedField = .username }
        }
        .alert(alertMessage, isPresented: $showAlert) { Button("OK", role: .cancel) { } }
        
        .onChange(of: registerStep) {
            switch registerStep {
            case 1:
                self.focusedField = .username
            default:
                self.focusedField = .none
            }
        }
    }
    
    func submit(completion: @escaping (Bool) -> Void) async {
        loading = true
        if !(!containsInvalidFirebaseCharacters(input: username) &&
             username.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil)  {
            
            alertMessage = "Usernames can only contain letters and numbers."
            showAlert = true
            loading = false
            completion(false)
        }
        if !(username.count >= 2)  {
            alertMessage = "Usernames must be atleast two characters or more."
            showAlert = true
            loading = false
            completion(false)
        }
        
        UserDefaults.standard.set(
            username.trimmingCharacters(in: .whitespacesAndNewlines),
            forKey: "username")

        addFirestoreUser() { error in
            if let error {
                print("Error creating user: \(error.localizedDescription)")
                loading = false
                completion(false)
            }
            removeRegInfoFromUserDefaults()
            userViewModel.isLoggedIn = true
            loading = false
            completion(true)
        }
    }
    
    func addFirestoreUser(completion: @escaping (Error?) -> Void) {
        Auth.auth().signInAnonymously { result, error in
            if let error {
                print("Error signing in... \(error.localizedDescription)")
                completion(error)
            }
            else {
                guard let currentUser = result?.user else {
                    completion(
                        NSError(
                            domain: "InvalidUser",
                            code: 400
                        )
                    )
                    return
                }
                let userRef = database.collection("users").document(currentUser.uid)
                createUserDocument(currentUser: currentUser, userRef: userRef) { error in
                    completion(error)
                }
            }
        }
    }

    func createUserDocument(currentUser: User, userRef: DocumentReference, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "username": username.lowercased(),
            "timezone": TimeZone.current.identifier,
            "created": FieldValue.serverTimestamp(),
        ]
        
        userRef.setData(userData) { error in
            if let error = error {
                print("Error adding user to Firestore: \(error.localizedDescription)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
}


#Preview {
    RegisterView()
}
