//
//  AZCachedAsyncImageService.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

public class AZCachedAsyncImageService: ObservableObject {
    @Published var uiImage: UIImage?
    
    internal func getImage(url: URL?,
                           cacheLocation: AZCacheLocation,
                           size: CGSize?) async throws {
        guard let url = url else {
            throw ServiceError.invalidUrl
        }
        switch cacheLocation {
        case .memory: try await storeAndRetrieveFromMemoryCache(url: url, size: size)
        case .fileSystem(let directory): try await storeAndRetrieveFromFileSystemCache(directory: directory, url: url, size: size)
        }
    }
    
    private func storeAndRetrieveFromMemoryCache(url: URL,
                                                 size: CGSize?) async throws {
        let cacheKey = url.absoluteString
        if let cachedImage = AZImageCache.shared[cacheKey] {
            if let size = size {
                let resizedImage = AZCachedAsyncImageService.resizeImage(image: cachedImage, targetSize: size)
                DispatchQueue.main.async {
                    self.uiImage = resizedImage
                }
            }
            DispatchQueue.main.async {
                self.uiImage = cachedImage
            }
        } else {
            let (data, _) = try await URLSession.shared.data(from: url)
            let cachedImage = AZCachedAsyncImageService.cacheAndReturnImage(key: cacheKey,
                                                                            data: data,
                                                                            size: size)
            DispatchQueue.main.async {
                self.uiImage = cachedImage
            }
        }
    }
    
    private func storeAndRetrieveFromFileSystemCache(directory: URL?, url: URL, size: CGSize?) async throws {
        let fileName = url.asValidFileName
        let directory = directory ?? FileManager.documentsDirectory
        let fileURL = directory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            publishImage(using: data, size: size)
        } else {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
            publishImage(using: data, size: size)
        }
    }
    
    private func publishImage(using data: Data, size: CGSize?) {
        var cachedImage = UIImage(data: data)
        if let size = size {
            cachedImage = AZCachedAsyncImageService.resizeImage(image: cachedImage, targetSize: size)
        }
        DispatchQueue.main.async {
            self.uiImage = cachedImage
        }
    }
    
    private static func eagerLoadImage(url: URL, size: CGSize? = nil) async throws {
        let cacheKey = url.absoluteString
        guard AZImageCache.shared[cacheKey] == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            _ = cacheAndReturnImage(key: cacheKey, data: data, size: size)
        } catch {
            throw error
        }
    }
    
    public static func eagerLoadImages(from urlStrings: [String], size: CGSize? = nil) async throws {
        let urls = urlStrings.compactMap { URL(string: $0) }
        await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try await self.eagerLoadImage(url: url, size: size)
                }
            }
        }
    }
    
    private static func cacheAndReturnImage(key: String,
                                            data: Data,
                                            size: CGSize? = nil) -> UIImage? {
        let originalImage = UIImage(data: data)
        AZImageCache.shared[key] = originalImage
        if let size = size {
            let resizedImage = resizeImage(image: originalImage, targetSize: size)
            return resizedImage
        } else {
            return originalImage
        }
    }
    
    private static func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
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
        
        return newImage
    }
    
    public enum ServiceError: Error {
        case invalidUrl
    }
}
