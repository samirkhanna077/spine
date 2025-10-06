//
//  ProfilePictureView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 3/17/25.
//

import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    let size: CGFloat
    let thickOutline: Bool

    init(
        profileImage: UIImage?,
        size: CGFloat,
        thickOutline: Bool = false
    ) {
        self.size = size
        self.thickOutline = thickOutline
    }

    var body: some View {
        ZStack {
            if let image = userViewModel.profilePicture {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            Circle()
                .stroke(.gray, lineWidth: thickOutline ? 2 : 1)
                .frame(width: size)
        }
        .frame(width: size, height: size)
    }
}
