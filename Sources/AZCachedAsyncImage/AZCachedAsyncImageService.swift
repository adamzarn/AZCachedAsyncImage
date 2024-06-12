//
//  AZCachedAsyncImageService.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

public class AZCachedAsyncImageService: ObservableObject {
    @Published var uiImage: UIImage?
    @Published var cacheURL: URL?
    
    internal func getImage(url: URL?,
                           cacheLocation: AZCacheLocation,
                           size: CGSize?) async throws {
        guard let url = url else {
            throw ServiceError.invalidUrl
        }
        switch cacheLocation {
        case .memory:
            try await storeAndRetrieveFromMemoryCache(url: url,
                                                      size: size)
        case .fileSystem(let directory, let combinedFileSizesLimit):
            try await storeAndRetrieveFromFileSystemCache(directory: directory,
                                                          combinedFileSizesLimit: combinedFileSizesLimit,
                                                          url: url,
                                                          size: size)
        }
    }
    
    private func storeAndRetrieveFromMemoryCache(url: URL,
                                                 size: CGSize?) async throws {
        let cacheKey = url.absoluteString
        if let cachedImage = AZImageCache.shared[cacheKey] {
            if let size = size {
                AZCachedAsyncImageService.resizeImage(image: cachedImage, targetSize: size) { resizedImage in
                    DispatchQueue.main.async {
                        self.uiImage = resizedImage
                    }
                }
            }
            DispatchQueue.main.async {
                self.uiImage = cachedImage
            }
        } else {
            let (data, _) = try await URLSession.shared.data(from: url)
            AZCachedAsyncImageService.cacheAndReturnImage(key: cacheKey,
                                                          data: data,
                                                          size: size) { cachedImage in
                DispatchQueue.main.async {
                    self.uiImage = cachedImage
                }
            }
        }
    }
    
    private func storeAndRetrieveFromFileSystemCache(directory: URL?,
                                                     combinedFileSizesLimit: AZCombinedFileSizesLimit?,
                                                     url: URL,
                                                     size: CGSize?) async throws {
        let fileName = url.asValidFileName
        let directory = directory ?? FileManager.documentsDirectory
        let fileURL = directory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            publishImage(using: data, size: size, cacheURL: fileURL)
        } else {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            publishImage(using: data, size: size, cacheURL: fileURL)
        }
        deleteFileIfNecessary(basedOn: combinedFileSizesLimit)
    }
    
    private func publishImage(using data: Data, size: CGSize?, cacheURL: URL?) {
        let cachedImage = UIImage(data: data)
        if let size = size {
            AZCachedAsyncImageService.resizeImage(image: cachedImage, targetSize: size) { resizedImage in
                DispatchQueue.main.async {
                    self.uiImage = resizedImage
                    self.cacheURL = cacheURL
                }
            }
        } else {
            DispatchQueue.main.async {
                self.uiImage = cachedImage
                self.cacheURL = cacheURL
            }
        }
    }
    
    private func deleteFileIfNecessary(basedOn combinedFileSizesLimit: AZCombinedFileSizesLimit?) {
        if let combinedFileSizesLimit = combinedFileSizesLimit {
            let urlsOfPreviouslyCachedFiles = FileManager.getAllURLs(in: FileManager.documentsDirectory,
                                                                     withPrefix: FileManager.fileNamePrefix)
            if combinedFileSizesLimit.asNumberOfBytes < urlsOfPreviouslyCachedFiles.combinedFileSizesInBytes {
                try? FileManager.deleteOldestFile(in: FileManager.documentsDirectory,
                                                  withPrefix: FileManager.fileNamePrefix)
            }
        }
    }
    
    private static func cacheAndReturnImage(key: String,
                                            data: Data,
                                            size: CGSize? = nil,
                                            completion: @escaping (UIImage?) -> Void) {
        let originalImage = UIImage(data: data)
        AZImageCache.shared[key] = originalImage
        if let size = size {
            resizeImage(image: originalImage, targetSize: size) { resizedImage in
                completion(resizedImage)
            }
        } else {
            completion(originalImage)
        }
    }
    
    private static func resizeImage(image: UIImage?,
                                    targetSize: CGSize,
                                    completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let image = image else { completion(nil); return }
            let size = image.size
            
            let widthRatio = targetSize.width/size.width
            let heightRatio = targetSize.height/size.height
            
            let ratio = widthRatio > heightRatio ? heightRatio : widthRatio
            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            completion(newImage)
        }
    }
    
    public enum ServiceError: Error {
        case invalidUrl
    }
}
