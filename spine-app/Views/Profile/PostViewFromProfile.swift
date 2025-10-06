import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct PostViewFromProfile: View {
    @State var post: Post
    @State private var user: UserModel?
    @State private var isLoading = true
    @State private var environmentImage: UIImage? = nil
    @State private var bookCoverImage: UIImage? = nil
    @State private var profileImage: UIImage? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading Post...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 20) {
                        // Top Image Section
                        ZStack(alignment: .bottom) {
                            if let environmentImage = environmentImage {
                                Image(uiImage: environmentImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .cornerRadius(16)
                                    .clipped()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(colors: [.clear, .black.opacity(0.4)],
                                                               startPoint: .top, endPoint: .bottom)
                                            )
                                    )
                            }

                            if let bookCoverImage = bookCoverImage {
                                Image(uiImage: bookCoverImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(10)
                                    .shadow(radius: 8)
                                    .padding(.bottom, -40)
                            }
                        }

                        // Post Metadata Section
                        VStack(alignment: .leading, spacing: 12) {
                            if let user = user {
                                Label(user.username, systemImage: "person.crop.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            Text("Created on \(post.createdAt, formatter: DateFormatter.shortDate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let caption = post.caption {
                                Text(caption)
                                    .font(.body)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                        // Book Details Section
                        if let book = post.bookMetaData {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Book Details")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                VStack(spacing: 12) {
                                    DetailRow(label: "Title", value: book.title, icon: "book.fill")
                                    DetailRow(label: "Author", value: book.author, icon: "person.fill")
                                    DetailRow(label: "Genre", value: book.genre, icon: "tag.fill")
                                    DetailRow(label: "Pages Read", value: "\(book.pagesRead) / \(book.pageCount)", icon: "doc.plaintext")
                                    
                                    if let timeRead = book.timeRead {
                                        DetailRow(label: "Time Read", value: formatTimeInterval(timeRead), icon: "clock.fill")
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Post Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchPostDetails()
            }
        }
    }
    
    // Clean reusable row
    @ViewBuilder
    func DetailRow(label: String, value: String, icon: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }


    private func fetchPostDetails() {
        guard !self.post.id.isEmpty else {
            return
        }
        
        fetchUserDetails(userID: post.userID)
        fetchImageURLs()
        self.isLoading = false
    }

    private func fetchUserDetails(userID: String) {
        guard !userID.isEmpty else {
            return
        }
        
        database.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }

            guard let data = snapshot?.data() else {
                print("User not found.")
                return
            }

            DispatchQueue.main.async {
                self.user = UserModel(
                    id: snapshot?.documentID,
                    username: data["username"] as? String ?? "",
                    dateCreated: (data["dateCreated"] as? Timestamp)?.dateValue() ?? Date(),
                    timezone: data["timezone"] as? String ?? "UTC",
                    profileImageID: data["profileImageID"] as? String ?? ""
                )
            }
        }
    }

    private func fetchImageURLs() {
        if let environmentImageID = post.imageID {
            ImageManager.instance.get(imageID: environmentImageID) { image in
                self.environmentImage = image
            }
        }
        if let bookCoverImageID = post.bookCoverImageID {
            ImageManager.instance.get(imageID: bookCoverImageID) { image in
                self.bookCoverImage = image
            }
        }
        if let profileImageID = user?.profileImageID {
            ImageManager.instance.get(imageID: profileImageID) { image in
                self.profileImage = image
            }
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes)m \(seconds)s"
    }
}

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
