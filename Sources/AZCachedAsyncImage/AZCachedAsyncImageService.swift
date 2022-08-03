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
        let urlString = url.absoluteString
        if let uiImage = ImageCache.shared[urlString] {
            DispatchQueue.main.async {
                self.uiImage = uiImage
            }
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let uiImage = AZCachedAsyncImageService.cacheAndReturnImage(urlString: urlString,
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
    
    private static func eagerLoadImage(url: URL, size: CGSize? = nil) async throws {
        let urlString = url.absoluteString
        guard ImageCache.shared[urlString] == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            _ = cacheAndReturnImage(urlString: urlString, data: data, size: size)
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
    
    private static func cacheAndReturnImage(urlString: String,
                                            data: Data,
                                            size: CGSize? = nil) -> UIImage? {
        let originalImage = UIImage(data: data)
        if let size = size {
            let resizedImage = resizeImage(image: originalImage, targetSize: size)
            ImageCache.shared[urlString] = resizedImage
            return resizedImage
        } else {
            ImageCache.shared[urlString] = originalImage
            return originalImage
        }
    }
    
    private static func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        let size = image.size
        
        let widthRatio = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
