import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

enum FormError: LocalizedError, Identifiable {
    var id: String { localizedDescription }
    
    case invalidPageNumbers
    case currentPageExceedsTotal

    var errorDescription: String? {
        switch self {
        case .invalidPageNumbers:
            return "Pages cannot be negative. Please enter valid numbers."
        case .currentPageExceedsTotal:
            return "Current page cannot exceed total pages."
        }
    }
}

struct PostDataView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    var environmentImage: UIImage?
    var bookCoverImage: UIImage?
    
    @State private var caption: String = ""
    @State private var currentPage: String = ""
    @State private var bookMetaData: BookMetaData
    @State private var isUploading = false
    @State private var isAddingNewBook = false
    @State private var newBookTitle: String = ""
    @State private var newBookAuthor: String = ""
    @State private var newBookGenre: String = ""
    @State private var selectedPostType: PostType?
    @State private var showErrorAlert = false
    @State private var formError: FormError?
    
    init(environmentImage: UIImage? = nil, bookCoverImage: UIImage? = nil, bookMetaData: BookMetaData = BookMetaData(), selectedOption: PostType) {
        self.environmentImage = environmentImage
        self.bookCoverImage = bookCoverImage
        _bookMetaData = State(initialValue: bookMetaData)
        _selectedPostType = State(initialValue: selectedOption)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 📸 Image Preview
                ZStack {
                    if let bg = environmentImage {
                        Image(uiImage: bg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 250, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    if let cover = bookCoverImage {
                        Image(uiImage: cover)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 6)
                            .offset(x: 50, y: 50)
                    }
                }
                .padding(.top)

                // 📝 Post Form Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Post Details")
                        .font(.headline)

                    TextField("Write a caption...", text: $caption)
                        .textFieldStyle(CustomInputStyle())
                    
                    Divider()

                    if selectedPostType == .newBook {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            VStack(spacing: 10) {
                                TextField("Book Title", text: $newBookTitle)
                                    .textFieldStyle(CustomInputStyle())
                                
                                TextField("Author", text: $newBookAuthor)
                                    .textFieldStyle(CustomInputStyle())
                                
                                TextField("Genre", text: $newBookGenre)
                                    .textFieldStyle(CustomInputStyle())
                            }
                            
                            Divider()

                            TextField("Total Pages", text: $bookMetaData.pageCount)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomInputStyle())
                            
                            TextField("Current Page", text: $currentPage)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomInputStyle())
                                                        
                            if !bookMetaData.title.isEmpty {
                                Text("📚 Added: \(bookMetaData.title)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // 🚀 Share Button
                Button(action: {
                    guard validateForm() else { return }

                    bookMetaData.title = newBookTitle
                    bookMetaData.author = newBookAuthor
                    bookMetaData.genre = newBookGenre
                    
                    dismissKeyboard()
                    Task { await uploadPost() }
                }) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Label("Share", systemImage: "square.and.arrow.up.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .foregroundColor(.white)
                .background(isUploading ? Color.gray : Color.blue)
                .cornerRadius(12)
                .disabled(isUploading)
                .alert(item: $formError) { error in
                    Alert(title: Text("Oops!"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
                }

            }
            .padding()
        }
        .navigationTitle("Finish Post")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(.keyboard)
    }

    private func uploadPost() async {
        DispatchQueue.main.async {
            isUploading = true
        }

        guard let userID = userViewModel.userModel?.id else { return }
        guard let environmentImage = environmentImage, let bookCoverImage = bookCoverImage else { return }

        let postID = UUID().uuidString.lowercased()
        
        let bookMetaData = BookMetaData(
            title: bookMetaData.title,
            author: bookMetaData.author,
            genre: bookMetaData.genre,
            pagesRead: currentPage,
            pageCount: bookMetaData.pageCount
        )

        // Upload environment image first
        ImageManager.instance.uploadImage(environmentImage) { result in
            switch result {
            case .success(let environmentImageID):
                print("Environment image uploaded successfully: \(environmentImageID)")

                // Upload book cover image next
                ImageManager.instance.uploadImage(bookCoverImage) { result in
                    switch result {
                    case .success(let bookCoverImageID):
                        print("Book cover image uploaded successfully: \(bookCoverImageID)")
                        
                        let bookMetaDataDict: [String: Any] = [
                            "title": bookMetaData.title,
                            "author": bookMetaData.author,
                            "genre": bookMetaData.genre,
                            "pagesRead": bookMetaData.pagesRead,
                            "pageCount": bookMetaData.pageCount
                        ]

                        let newPost: [String: Any] = [
                            "id": postID,
                            "userID": userID,
                            "createdAt": Timestamp(date: Date()),
                            "environmentImageID": environmentImageID, // Store the environment image ID
                            "bookCoverImageID": bookCoverImageID,     // Store the book cover image ID
                            "caption": caption,
                            "bookMetaData": bookMetaDataDict,
                        ]
                                                
                        // Save the post data to Firestore
                        database.collection("posts").document(postID).setData(newPost) { error in
                            if let error = error {
                                print("Error saving post: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    isUploading = false
                                }
                                return
                            }
                            
                            print("Post saved successfully!")
                            
                            database.collection("users").document(userID).updateData([
                                "posts": FieldValue.arrayUnion([postID])
                            ]) { error in
                                if let error = error {
                                    print("Error updating user's post array: \(error.localizedDescription)")
                                } else {
                                    print("Post added to user document successfully!")
                                    
                                    clearFormData {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            isUploading = false
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }
                            }
                        }

                    case .failure(let error):
                        print("Book cover image upload failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            isUploading = false
                        }
                    }
                }

            case .failure(let error):
                print("Environment image upload failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isUploading = false
                }
            }
        }
    }


    // Clear the form data after post
    private func clearFormData(completion: @escaping () -> Void) {
        caption = ""
        currentPage = ""
        bookMetaData = BookMetaData()
        completion()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func validateForm() -> Bool {
        guard let current = Int(currentPage), let total = Int(bookMetaData.pageCount) else {
            formError = .invalidPageNumbers
            return false
        }
        
        if current < 0 || total < 0 {
            formError = .invalidPageNumbers
            return false
        }
        
        if current > total {
            formError = .currentPageExceedsTotal
            return false
        }
        
        return true
    }
}


// MARK: - Reusable Input Style
struct CustomInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }
}
