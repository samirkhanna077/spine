import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ReadingLogView: View {
    @State private var booksRead: [BookMetaData] = []
    @State private var images: [String: UIImage] = [:]
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showAddBookSheet = false

    // New Book Fields
    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var pagesRead = ""
    @State private var pageCount = ""
    @State private var coverImageURLString = ""
    @State private var selectedUIImage: UIImage?
    @State private var showImagePicker = false
    @State private var showingErrorDialog = false

    // Editing State
    @State private var isEditing = false
    @State private var selectedBook: BookMetaData?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading your books...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding()
                } else if booksRead.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No current books read.")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                    .padding(.top, 50)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(booksRead, id: \.self) { book in
                                HStack(spacing: 12) {
                                    // Book Cover Image
                                    if let imageID = book.coverImageURL?.absoluteString,
                                       let image = self.images[imageID] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 50, height: 70)
                                            .cornerRadius(8)
                                    } else {
                                        Color.gray.opacity(0.2)
                                            .frame(width: 50, height: 70)
                                            .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title)
                                            .font(.headline)
                                        Text(book.author)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Show progress or a green tick if pages are completed
                                    if let pagesReadInt = Int(book.pagesRead), let pageCountInt = Int(book.pageCount) {
                                        if pagesReadInt == pageCountInt {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .imageScale(.large)
                                        } else {
                                            Text("\(pagesReadInt)/\(pageCountInt)")
                                                .font(.footnote)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    // Edit Button
                                    Button(action: {
                                        selectedBook = book
                                        pagesRead = book.pagesRead
                                        pageCount = book.pageCount
                                        isEditing = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                            .imageScale(.large)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }

                Spacer()

                Button(action: {
                    showAddBookSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Book")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Reading Log")
            .onAppear(perform: fetchBooksRead)
            .sheet(isPresented: $showAddBookSheet) {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Add a New Book")
                            .font(.title2)
                            .bold()

                        Group {
                            TextField("Title", text: $title)
                            TextField("Author", text: $author)
                            TextField("Genre", text: $genre)
                            TextField("Pages Read", text: $pagesRead)
                                .keyboardType(.numberPad)
                            TextField("Total Page Count", text: $pageCount)
                                .keyboardType(.numberPad)
                            
                            // Display the selected cover image if any
                            if let selectedUIImage = selectedUIImage {
                                Image(uiImage: selectedUIImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                                    .padding(.top)
                            }

                            Button(action: {
                                showImagePicker = true
                            }) {
                                Text(selectedUIImage == nil ? "Select Cover Image" : "Change Cover Image")
                                    .foregroundColor(.blue)
                            }
                            .sheet(isPresented: $showImagePicker) {
                                ImagePicker(image: $selectedUIImage)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                        Button(action: {
                            submitBook()
                        }) {
                            Text("Submit")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding(.top, 40)
                }
            }
            .sheet(isPresented: $isEditing) {
                EditBookForm(book: $selectedBook, pagesRead: $pagesRead, pageCount: $pageCount, isEditing: $isEditing, onSave: updateBook)
            }
            .alert(isPresented: $showingErrorDialog) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    func fetchBooksRead() {
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User not logged in."
                isLoading = false
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                if let data = document?.data(),
                   let booksData = data["booksRead"] as? [[String: Any]] {
                    self.booksRead = booksData.compactMap { dict in
                        guard let title = dict["title"] as? String,
                              let author = dict["author"] as? String,
                              let genre = dict["genre"] as? String,
                              let pagesRead = dict["pagesRead"] as? String,
                              let pageCount = dict["pageCount"] as? String else {
                            return nil
                        }
                        let coverURL = URL(string: dict["coverImageURL"] as? String ?? "")
                        return BookMetaData(title: title, author: author, genre: genre, pagesRead: pagesRead, pageCount: pageCount, coverImageURL: coverURL)
                    }
                    
                    // Fetch the cover images for each book from Firebase Storage
                    fetchImageURLs(for: booksRead) {
                        self.booksRead = booksRead
                    }
                } else {
                    self.booksRead = []
                }
            }
        }
    
    private func fetchImageURLs(for books: [BookMetaData], completion: @escaping () -> Void) {
        for book in books {
            guard let coverImageURLString = book.coverImageURL?.absoluteString else { continue }
            
            ImageManager.instance.get(imageID: coverImageURLString) { image in
                if let image = image {
                    self.images[coverImageURLString] = image
                    print("Image fetched for \(coverImageURLString)") // Debugging
                } else {
                    print("Failed to fetch image for \(coverImageURLString)") // Debugging
                }
            }
        }
        completion()
    }

    func submitBook() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            showingErrorDialog = true
            return
        }

        // Input validation
        guard let pagesReadInt = Int(pagesRead),
              let pageCountInt = Int(pageCount),
              pagesReadInt >= 0,
              pageCountInt >= 0,
              pagesReadInt <= pageCountInt else {
            errorMessage = "Invalid page counts."
            showingErrorDialog = true
            return
        }

        // Upload the cover image to Firebase Storage if selected
        if let selectedUIImage = selectedUIImage {
            // Use the custom ImageManager instance to handle image upload
            ImageManager.instance.uploadImage(selectedUIImage) { result in
                switch result {
                case .success(let imageID):
                    print("Cover image uploaded successfully: \(imageID)")
                    
                    // Construct the Firestore URL for the image
                    let imageURL = "\(imageID)"
                    
                    // Save the book with the image URL in Firestore
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(userId)

                    let bookDict: [String: Any] = [
                        "title": title,
                        "author": author,
                        "genre": genre,
                        "pagesRead": pagesRead,
                        "pageCount": pageCount,
                        "coverImageURL": imageURL // Store the image URL referencing the imageID
                    ]

                    userRef.updateData([
                        "booksRead": FieldValue.arrayUnion([bookDict])
                    ]) { error in
                        if let error = error {
                            errorMessage = "Failed to add book: \(error.localizedDescription)"
                            showingErrorDialog = true
                            return
                        }

                        // Refresh the books list after adding the book
                        fetchBooksRead()
                        clearForm()
                        showAddBookSheet = false
                    }

                case .failure(let error):
                    errorMessage = "Failed to upload cover image: \(error.localizedDescription)"
                    showingErrorDialog = true
                }
            }
        } else {
            errorMessage = "No image selected."
            showingErrorDialog = true
        }
    }
    
    struct EditBookForm: View {
        @Binding var book: BookMetaData?
        @Binding var pagesRead: String
        @Binding var pageCount: String
        @Binding var isEditing: Bool
        var onSave: () -> Void

        var body: some View {
            VStack(spacing: 16) {
                Text("Edit Book")
                    .font(.title2)
                    .bold()

                TextField("Pages Read", text: $pagesRead)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Total Page Count", text: $pageCount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: onSave) {
                    Text("Save Changes")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Button(action: {
                    isEditing = false // This will dismiss the EditBookForm
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    func updateBook() {
        guard let selectedBook = selectedBook, let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in or no book selected."
            showingErrorDialog = true
            clearForm()
            return
        }

        // Validate the pagesRead and pageCount inputs
        guard let pagesReadInt = Int(pagesRead), let pageCountInt = Int(pageCount) else {
            errorMessage = "Please enter valid numeric values for Pages Read and Total Page Count."
            showingErrorDialog = true
            clearForm()
            return
        }
        
        // Ensure pagesRead is not greater than pageCount
        if pagesReadInt > pageCountInt {
            errorMessage = "Pages Read cannot be greater than Total Page Count."
            showingErrorDialog = true
            clearForm()
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        // Fetch current user data
        userRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Error fetching user data: \(error.localizedDescription)"
                showingErrorDialog = true
                return
            }
            
            guard let data = document?.data(),
                  var booksReadArray = data["booksRead"] as? [[String: Any]] else {
                errorMessage = "No books found for the user."
                showingErrorDialog = true
                return
            }
            
            // Find the index of the book to update
            if let index = booksReadArray.firstIndex(where: { $0["title"] as? String == selectedBook.title &&
                                                              $0["author"] as? String == selectedBook.author }) {
                // Update the book at the found index
                booksReadArray[index]["pagesRead"] = pagesRead
                booksReadArray[index]["pageCount"] = pageCount
                booksReadArray[index]["coverImageURL"] = selectedBook.coverImageURL?.absoluteString ?? ""

                // Update the booksRead array in Firestore
                userRef.updateData([
                    "booksRead": booksReadArray
                ]) { error in
                    if let error = error {
                        errorMessage = "Failed to update book: \(error.localizedDescription)"
                        showingErrorDialog = true
                    } else {
                        // Refresh the books list after updating
                        fetchBooksRead()
                        isEditing = false
                    }
                }
                clearForm()
            } else {
                errorMessage = "Book not found."
                showingErrorDialog = true
            }
        }
    }

    func clearForm() {
        title = ""
        author = ""
        genre = ""
        pagesRead = ""
        pageCount = ""
        coverImageURLString = ""
        selectedUIImage = nil
        errorMessage = nil
    }
}
