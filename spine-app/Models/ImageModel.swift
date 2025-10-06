import SwiftUI
import FirebaseStorage
import Combine
import FirebaseFirestore
import FirebaseAuth

class ImageManager: ObservableObject {
    
    /// singleton formed at compile time
    static let instance = ImageManager()
    
    /// cache persists for lifetime of app session
    private var cache = NSCache<NSString, UIImage>()
    private let cacheLimit = 100 // arbitrary
    
    /// directory for disk cache
    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ImageCache")
    }
    
    init() {
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        self.cache.countLimit = cacheLimit
    }
    
    /// gets PFP from image cache if it exists locally, otherwise fetch from cloud storage and cache
    /// - Parameters:
    ///   - imageID: UUID string generated on upload
    ///   - completion: returns optional  UIImage object
    func get(imageID: String, completion: @escaping (UIImage?) -> Void) {
        if imageID.isEmpty {
            completion(nil)
            return
        }
        
        /// cache check WHILE app is running
        if let cachedImage = cache.object(forKey: imageID as NSString) {
            completion(cachedImage)
            return
        }
        
        /// Check disk cache
        let diskCacheURL = cacheDirectory.appendingPathComponent(imageID)
        if let diskCachedImage = UIImage(contentsOfFile: diskCacheURL.path) {
            cache.setObject(diskCachedImage, forKey: imageID as NSString)
            completion(diskCachedImage)
            return
        }
        
        /// image does not exist locally, fetch from cloud storage
        let storageRef = storage.reference(withPath: "images/\(imageID)")
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error in ImageManager.get() - \(error)")
                completion(nil)
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            // Write to local cache and disk
            self.cacheImage(image, forKey: imageID as NSString)
            try? data.write(to: diskCacheURL)
            completion(image)
        }
    }
    
    /// fetch multiple images asynchronously; useful for search & team view
    func getAsync(imageIDs: [String], completion: @escaping ([UIImage?]) -> Void) {
        let group = DispatchGroup()
        var images: [UIImage?] = Array(repeating: nil, count: imageIDs.count)
        
        for (index, imageID) in imageIDs.enumerated() {
            group.enter()
            get(imageID: imageID) { image in
                images[index] = image
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(images)
        }
    }
    
    
    /// upload an image to Firebase Storage and store reference
    /// automatically compresses image down to around 4MB; caches on completion
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        var cQ = 1.0
        guard var imageData = image.jpegData(compressionQuality: 1.0) else {
            completion(.failure(NSError(
                domain: "Invalid image data",
                code: -1, userInfo: nil)))
            return
        }
        let maxBytes = 5 * 1024 * 1024
        
        /// compression down to ~4.2 MB
        while imageData.count > maxBytes {
            print("compression triggered", imageData.count)
            cQ -= 0.1
            guard let tempImageData = image.jpegData(compressionQuality: cQ) else {
                completion(.failure(NSError(
                    domain: "Aborting - failed image compression",
                    code: -1, userInfo: nil)))
                return
            }
            imageData = tempImageData
        }

        let imageID = UUID().uuidString.lowercased()
        self.cacheImage(image, forKey: imageID as NSString)
        
        // Save to disk cache
        let diskCacheURL = cacheDirectory.appendingPathComponent(imageID)
        try? imageData.write(to: diskCacheURL)

        /// upload to cloud storage
        let storageRef = storage.reference(withPath: "images/\(imageID)")
        
        if let uploadData = imageData as Data? {
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            storageRef.putData(uploadData, metadata: metaData) { metadata, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                // Update the cache with the new image
                completion(.success(imageID))
            }
        }
    }
    
    /// best practice is to give users the option to clear their cache/filesystem
    func clearCache() {
        cache.removeAllObjects()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    /// utility to delete single object from cache by string
    func removeFromCache(imageKey: String) {
        cache.removeObject(forKey: imageKey as NSString)
        let diskCacheURL = cacheDirectory.appendingPathComponent(imageKey)
        try? FileManager.default.removeItem(at: diskCacheURL)
    }
    
    private func cacheImage(_ image: UIImage, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }
}
