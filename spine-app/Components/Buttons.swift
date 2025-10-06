//
//  Buttons.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/17/25.
//

import Foundation
import SwiftUI


struct PrimaryButton: View {
    var text: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue)
            Text(text)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .tracking(1.3)
        }.frame(width: screenWidth-50, height: 60)
    }
}

struct SecondaryButton: View {
    var text: String
    var padding: CGFloat = 50.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.teal)
            Text(text)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .tracking(1.3)
        }.frame(width: screenWidth-padding, height: 60)
    }
}
