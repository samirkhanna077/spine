import SwiftUI
import UIKit

struct PostView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var selectedOption: PostType? = nil
    @State private var environmentImage: UIImage? = nil
    @State private var bookCoverImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var selectingBookCover = false
    @State private var navigateToPost = false
    @State private var selectionMessage: String? = "Step 1: Select a background photo."

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create a Post")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Select images to make a post")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Option Buttons
                    HStack(spacing: 16) {
                        OptionButton(title: "Make New Post", icon: "plus.circle.fill", color: .green) {
                            startPostFlow(type: .newBook)
                        }
                    }

                    // Progress Message
                    if let message = selectionMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .transition(.opacity)
                    }

                    // Image Selection Steps
                    if let environmentImage = environmentImage {
                        VStack(spacing: 12) {
                            ZStack {
                                Image(uiImage: environmentImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 250, height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                    )
                                    .shadow(radius: 4)
                                
                                if let bookCoverImage = bookCoverImage {
                                    Image(uiImage: bookCoverImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(radius: 6)
                                        .offset(x: 60, y: 60)
                                }
                            }

                            // Choose Book Cover
                            if bookCoverImage == nil {
                                Button {
                                    selectingBookCover = true
                                    showingImagePicker = true
                                } label: {
                                    Label("Choose Book Cover", systemImage: "book.closed")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.top)
                        .onAppear() {
                            selectionMessage = "Now select the book cover."
                        }
                    }

                    // Continue Button
                    if bookCoverImage != nil {
                        Button(action: {
                            navigateToPost = true
                        }) {
                            Label("Continue", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 12)
                        .transition(.scale)
                    }
                }
                .padding()
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToPost) {
                PostDataView(
                    environmentImage: environmentImage,
                    bookCoverImage: bookCoverImage,
                    bookMetaData: BookMetaData(),
                    selectedOption: selectedOption ?? .existingBook
                )
                .onDisappear() {
                    resetPostView()
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: selectingBookCover ? $bookCoverImage : $environmentImage)
            }
        }
    }

    private func startPostFlow(type: PostType) {
        selectedOption = type
        showingImagePicker = true
        selectingBookCover = false
    }

    private func resetPostView() {
        withAnimation {
            environmentImage = nil
            bookCoverImage = nil
            selectedOption = nil
            selectionMessage = nil
            showingImagePicker = false
            selectingBookCover = false
        }
    }
}


enum PostType {
    case existingBook
    case newBook
}

struct OptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(color)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(width: screenWidth - 25, height: 100)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

