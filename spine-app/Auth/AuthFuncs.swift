//
//  AuthFuncs.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/17/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// INPUT VALIDATION
func containsInvalidFirebaseCharacters(input: String) -> Bool {
    return input.rangeOfCharacter(from: invalidChars) != nil
}

let invalidChars: CharacterSet = [".", "$", "#", "[", "]", "/"]


func formatPhoneNumberWithPlusOne(_ number: String) -> String {
    let numbersOnly = number.filter { $0.isNumber }
    
    guard numbersOnly.count >= 10 else {
        return ""
    }
    
    let formattedNumber = "+1" + numbersOnly.suffix(10)
    return formattedNumber
}


func cleanPhoneNumber(_ number: String) -> String {
    return number.filter { $0.isNumber }
}

func removeRegInfoFromUserDefaults() {
    UserDefaults.standard.removeObject(forKey: "phoneNumber")
    UserDefaults.standard.removeObject(forKey: "username")
    UserDefaults.standard.removeObject(forKey: "authVerificationID")
}

