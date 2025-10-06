//
//  IntroView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/17/25.
//

import SwiftUI


struct IntroView: View {
    @State private var showLogin: Bool = false
    @State private var showResgister: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Spine")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                VStack(spacing: 10) {

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 300, height: 50)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showResgister.toggle()
                            }
                        Text("Create Account")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .navigationDestination(isPresented: $showResgister) {
                        RegisterView()
                    }
                }
            }
            .padding()
        }
    }
}


#Preview {
    IntroView()
}
