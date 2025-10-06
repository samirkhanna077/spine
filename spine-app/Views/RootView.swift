//
//  RootView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/2/25.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    
    var body: some View {
        Group {
            if Auth.auth().currentUser == nil || userViewModel.isLoggedIn == false {
                IntroView()
            }
            else if userViewModel.dataFetched == false {
                ProgressView()
                    .task {
                        await userViewModel.fetchUserData()
                    }
            }
            else {
                ContentView()
            }
        }
        .environmentObject(userViewModel)
    }
}
