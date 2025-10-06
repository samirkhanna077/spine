//
//  RegUsername.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/17/25.
//

import Foundation
import SwiftUI
import Combine


struct Username: View {
    @Binding var username: String
    var focused: FocusState<RegisterView.Field?>.Binding
    
    var body: some View {
        VStack (alignment: .leading, spacing: 10) {
            VStack (alignment: .leading, spacing: 20) {
                Text("My username is")
                    .foregroundStyle(.white)
                    .font(.system(size: 36, weight: .bold))
                
                InputUsername(value: $username, focused: focused)
                    .frame(alignment: .leading)
            }
            Text("You will not be able to change this later")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 40)
    }
}

struct InputUsername: View {
    @Binding var value: String
    var focused: FocusState<RegisterView.Field?>.Binding
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("@")
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .bold))
                
                TextField("", text: $value,
                          prompt: Text("username")
                    .foregroundStyle(.white.opacity(0.6))
                )
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 40)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .keyboardType(.alphabet)
                .focused(focused, equals: .username)
                .onReceive(Just(self.value)) { inputValue in
                    self.value = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if inputValue.count > 20 {
                        self.value = String(inputValue.prefix(20))
                    }
                }
            }
            Rectangle()
                .frame(height: 3.0)
                .foregroundStyle(.white)
                .opacity(0.5)
        }
    }
}
