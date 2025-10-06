//
//  ProfileView.swift
//  spine-app
//
//  Created by Ethan Gibbs on 3/17/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var userPosts: [Post] = []
    @State private var images: [String: UIImage] = [:]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        NavigationView {
            ZStack {
                Background()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Profile Header (Image + Username)
                        HStack(spacing: 20) {
                            NavigationLink(destination: EditProfileView()) {
                                ProfilePictureView(
                                    profileImage: userViewModel.profilePicture,
                                    size: 75,
                                    thickOutline: true
                                )
                                
                                VStack(alignment: .leading) {
                                    Text(userViewModel.userModel?.username ?? "...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.6)
                                        .bold()
                                        .lineLimit(1)
                                        .fontDesign(.monospaced)
                                    
                                    Text("edit")
                                        .font(.subheadline)
                                        .fontDesign(.monospaced)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.trailing, 10)
                            
                            Spacer()
                            
                            VStack {
                                Text("0")
                                    .font(.headline)
                                    .bold()
                                    .fontDesign(.monospaced)

                                Text("Followers")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fontDesign(.monospaced)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Dynamic Post Grid
                        if userPosts.isEmpty {
                            Text("No posts yet")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            let imageSize = UIScreen.main.bounds.width / 3.2
                            let gridSpacing: CGFloat = 10 // Ensures equal spacing

                            LazyVGrid(columns: columns, spacing: gridSpacing) {
                                ForEach(userPosts) { post in
                                    Group {
                                        NavigationLink(destination: PostViewFromProfile(post: post)) {
                                            if let imagePath = post.imageID, let image = self.images[imagePath] {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .resizable()
                                                    .aspectRatio(1, contentMode: .fill)
                                                    .frame(width: imageSize, height: imageSize)
                                                    .cornerRadius(10)
                                                    .clipped()
                                            }
                                            else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: imageSize, height: imageSize)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, gridSpacing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                }
            }
            .onAppear {
                fetchUserPosts()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Profile"))
        }
    }
    
    // Fetch user's posts from Firestore
    private func fetchUserPosts() {
        guard let userID = userViewModel.userModel?.id else { return }
        
        database.collection("posts")
            .whereField("userID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }
                
                let posts = snapshot?.documents.compactMap { doc -> Post? in
                    let data = doc.data()
                    
                    // Fetching bookMetaData
                    let bookMetaDataData = data["bookMetaData"] as? [String: Any] ?? [:]
                    
                    // Extract individual fields from bookMetaData
                    let bookMetaData = BookMetaData(
                        title: bookMetaDataData["title"] as? String ?? "",
                        author: bookMetaDataData["author"] as? String ?? "",
                        genre: bookMetaDataData["genre"] as? String ?? "",
                        pagesRead: bookMetaDataData["pagesRead"] as? String ?? "0", // default value if nil
                        pageCount: bookMetaDataData["pageCount"] as? String ?? "0" // default value if nil
                    )
                    
                    // Return Post with populated bookMetaData
                    return Post(
                        id: doc.documentID,
                        userID: data["userID"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        imageID: data["environmentImageID"] as? String,
                        caption: data["caption"] as? String ?? "",
                        bookCoverImageID: data["bookCoverImageID"] as? String,
                        bookMetaData: bookMetaData // Pass the bookMetaData to the Post
                    )
                } ?? []

                
                DispatchQueue.main.async {
                    fetchImageURLs(for: posts) {
                        self.userPosts = posts
                    }
                }
            }
    }
    
    // Fetch Firebase Storage download URLs
    private func fetchImageURLs(for posts: [Post], completion: @escaping () -> Void) {
        for post in posts {
            guard let imagePath = post.imageID else { continue }
            
            ImageManager.instance.get(imageID: imagePath, completion: { image in
                self.images[imagePath] = image
            })
        }
        completion()
    }
}
