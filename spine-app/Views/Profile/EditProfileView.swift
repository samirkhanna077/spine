import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isUploading = false
    @State private var showUploadSuccess = false
    @State private var uploadError: String?

    var body: some View {
        VStack(spacing: 30) {
            // Profile image with overlay edit icon
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                    } else if let profileImage = userViewModel.profilePicture {
                        Image(uiImage: profileImage)
                            .resizable()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .shadow(radius: 6)
                .animation(.easeInOut, value: selectedImage)

                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: -4, y: -4)
                }
            }

            // Upload Button
            Button {
                uploadProfileImage()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Upload Profile Picture")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedImage == nil || isUploading)
            .opacity((selectedImage == nil || isUploading) ? 0.5 : 1)

            // Feedback message
            if showUploadSuccess {
                Label("Upload successful!", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }

            if let uploadError = uploadError {
                Label(uploadError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }

            // Logout Button
            Button {
                handleLogout()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func uploadProfileImage() {
        guard let image = selectedImage else { return }
        isUploading = true
        showUploadSuccess = false
        uploadError = nil

        ImageManager.instance.uploadImage(image) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let imageID):
                    print("Image uploaded with ID: \(imageID)")
                    if let userID = userViewModel.userModel?.id {
                        let reference = database.document("users/\(userID)")
                        reference.updateData(["profileImageID": imageID])
                        userViewModel.userModel?.profileImageID = imageID
                        userViewModel.profilePicture = image
                        showUploadSuccess = true
                    }
                case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                    uploadError = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                userViewModel.isLoggedIn = false
                userViewModel.dataFetched = false
            }
        } catch {
            print("Failed to log out...")
        }
    }
}

