//
//  AZCachedAsyncImageService.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

public enum AZCachedAsyncImageServiceError: Error {
    case invalidUrl
}

public class AZCachedAsyncImageService: ObservableObject {
    @Published var uiImage: UIImage?
    
    internal func getImage(url: URL?, size: CGSize? = nil) async throws {
        guard let url = url else {
            self.uiImage = UIImage()
            throw AZCachedAsyncImageServiceError.invalidUrl
        }
        let cacheKey = AZCachedAsyncImageService.getKey(for: url, and: size)
        if let uiImage = ImageCache.shared[cacheKey] {
            DispatchQueue.main.async {
                self.uiImage = uiImage
            }
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let uiImage = AZCachedAsyncImageService.cacheAndReturnImage(key: cacheKey,
                                                                            data: data,
                                                                            size: size)
                DispatchQueue.main.async {
                    self.uiImage = uiImage
                }
            } catch {
                throw error
            }
        }
    }
    
    private static func getKey(for url: URL, and size: CGSize?) -> String {
        var key = url.absoluteString
        if let size = size {
            key += "/\(size.width)/\(size.height)"
        }
        return key
    }
    
    private static func eagerLoadImage(url: URL, size: CGSize? = nil) async throws {
        let cacheKey = getKey(for: url, and: size)
        guard ImageCache.shared[cacheKey] == nil else { return }
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
        if let size = size {
            let resizedImage = resizeImage(image: originalImage, targetSize: size)
            ImageCache.shared[key] = resizedImage
            return resizedImage
        } else {
            ImageCache.shared[key] = originalImage
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
}
