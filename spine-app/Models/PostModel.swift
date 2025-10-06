//
//  PostModel.swift
//  spine-app
//
//  Created by Ethan Gibbs on 2/3/25.
//

import SwiftUI

struct Post: Identifiable, Hashable {
    var id: String
    var userID: String
    var createdAt: Date
    var imageID: String?
    var caption: String?
    var bookCoverImageID: String?
    var bookMetaData: BookMetaData?
    var likedBy: [String] = [] // <-- Add this
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userID)
        hasher.combine(createdAt)
        hasher.combine(imageID)
        hasher.combine(bookCoverImageID)
        hasher.combine(bookMetaData)
        hasher.combine(likedBy)
    }
}

struct BookMetaData: Equatable, Hashable {
    var title: String = ""
    var author: String = ""
    var genre: String = ""
    var pagesRead: String = ""
    var pageCount: String = ""
    var coverImageURL: URL?
    var timeRead: TimeInterval?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(author)
        hasher.combine(genre)
        hasher.combine(pagesRead)
        hasher.combine(pageCount)
        hasher.combine(coverImageURL)
        hasher.combine(timeRead)
    }
}
