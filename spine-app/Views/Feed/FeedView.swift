import SwiftUI
import FirebaseFirestore
import UIKit

//#Preview {
//    FeedView()
//        .environmentObject(UserViewModel())
//}

struct FeedView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State var feedPosts: [Post] = []
    
    var body: some View {
        NavigationView { // Wrap the entire screen in a NavigationView
            ZStack {
                Background()
                VStack {
                    Text("Spine")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.75))
                        .padding(.top)
                    
                    Divider()
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            ForEach(feedPosts, id: \.self) { post in
                                NavigationLink(destination: PostViewFromFeed(post: post)) {
                                    FeedCell(post: post, currentUserID: userViewModel.userModel?.id ?? "")
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    fetchAllPosts()
                }
            }
        }
    }
    
    private func fetchAllPosts() {
        database.collection("posts")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }
                
                let posts = snapshot?.documents.compactMap { postDoc -> Post? in
                    let data = postDoc.data()
                    
                    let bookMetaData = (data["bookMetaData"] as? [String: Any]).map { bookData in
                        BookMetaData(
                            title: bookData["title"] as? String ?? "",
                            author: bookData["author"] as? String ?? "",
                            genre: bookData["genre"] as? String ?? "",
                            pagesRead: bookData["pagesRead"] as? String ?? "",
                            pageCount: bookData["pageCount"] as? String ?? "",
                            coverImageURL: bookData["coverImageURL"] as? URL,
                            timeRead: bookData["timeRead"] as? TimeInterval
                        )
                    }
                    
                    return Post(
                        id: postDoc.documentID,
                        userID: data["userID"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        imageID: data["environmentImageID"] as? String,
                        caption: data["caption"] as? String ?? "",
                        bookCoverImageID: data["bookCoverImageID"] as? String,
                        bookMetaData: bookMetaData
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.feedPosts = posts.sorted(by: {$0.createdAt > $1.createdAt})
                }
            }
    }
}


struct FeedCell: View {
    var post: Post
    var currentUserID: String

    @State private var bookCoverImage: UIImage? = nil
    @State private var environmentImage: UIImage? = nil
    @State private var user: UserModel? = nil
    @State private var userPFP: UIImage? = nil
    @State private var isLiked = false
    @State private var likeCount: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // User profile info
                if let pfp = userPFP {
                    Circle()
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(uiImage: pfp)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle()) // Clip the image to fit inside the circle
                        )
                } else {
                    Circle()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(.white)
                        )

                }
                
                VStack(alignment: .leading) {
                    Text(user?.username ?? "...") // Assuming userID as the username for now
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(post.createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            // ZStack for Book Cover and Environment Image
            ZStack(alignment: .topTrailing) {
                
                // Environment image (background)
                if let imageID = post.imageID {
                    Image(uiImage: environmentImage ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(8)
                        .onAppear {
                            ImageManager.instance.get(imageID: imageID) { image in
                                self.environmentImage = image
                            }
                        }
                }
                
                // Book cover image (on top of the environment image)
                if let coverID = post.bookCoverImageID {
                    Image(uiImage: bookCoverImage ?? UIImage())
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 120)  // Set the book cover to be a vertical rectangle
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                        .offset(x: -20)  // Move the image 20 points to the left
                        .onAppear {
                            ImageManager.instance.get(imageID: coverID) { image in
                                self.bookCoverImage = image
                            }
                        }
                }
            }
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                toggleLike() // Double-tap to like as well
            })
            
            // Post caption below the images
            Text(post.caption ?? "No caption")
                .font(.body)
                .foregroundColor(.white)
                .padding(.top, 8)
                .lineLimit(3)
            
            // Action buttons (like, comment, share)
            HStack {
                Spacer()  // Pushes the heart button to the center

                Button(action: {
                    toggleLike()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .frame(width: 30, height: 30)
                        .padding(6)
                }

                Spacer()  // Ensures the heart button is centered by taking equal space on both sides
            }
            Text("\(likeCount) \(likeCount == 1 ? "like" : "likes")")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, -4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .foregroundColor(.gray)
            .padding(.top, 8)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 5)
        .onAppear {
            fetchUserDetails(userID: post.userID)
            checkIfLiked()
            fetchLikeCount()
        }
    }
    
    private func checkIfLiked() {
        let docRef = database.collection("posts").document(post.id)
            docRef.getDocument { document, error in
                if let data = document?.data(),
                   let likedBy = data["likedBy"] as? [String] {
                    self.isLiked = likedBy.contains(currentUserID)
                }
            }
    }
    
    func fetchLikeCount() {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let likedBy = data["likedBy"] as? [String] {
                likeCount = likedBy.count
            }
        }
    }
    
    // Toggle like state and trigger haptic feedback
    private func toggleLike() {
        let postID = post.id
        let docRef = database.collection("posts").document(postID)

        let update: [String: Any] = isLiked ?
            ["likedBy": FieldValue.arrayRemove([currentUserID])] :
            ["likedBy": FieldValue.arrayUnion([currentUserID])]

        docRef.updateData(update) { error in
            if let error = error {
                print("Error updating likes: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.isLiked.toggle()
                    self.likeCount += self.isLiked ? 1 : -1
                    
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }
    }
    
    private func fetchUserDetails(userID: String) {
        database.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("User not found.")
                return
            }
            
            
            let user = UserModel(
                id: snapshot?.documentID,
                username: data["username"] as? String ?? "Unknown",
                dateCreated: (data["dateCreated"] as? Timestamp)?.dateValue() ?? Date(),
                timezone: data["timezone"] as? String ?? "UTC",
                profileImageID: data["profileImageID"] as? String
            )
            
            var pfp: UIImage? = nil
            
            ImageManager.instance.get(imageID: user.profileImageID ?? "") { image in
                if let image = image {
                    pfp = image
                }
            }
            
            DispatchQueue.main.async {
                self.user = user
                self.userPFP = pfp
            }
        }
    }

    
    private func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}
