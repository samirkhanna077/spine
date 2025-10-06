//
//  SpineApp.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/2/25.
//

import SwiftUI
import FirebaseCore

@main
struct SpineApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userViewModel) // pass global state throughout app
                .preferredColorScheme(.dark)
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase Initialized Successfully")
        return true
    }
}

extension View {
    /// Dismisses the keyboard when called
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}


