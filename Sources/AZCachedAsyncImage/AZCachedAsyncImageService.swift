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

@MainActor
public class AZCachedAsyncImageService: ObservableObject {
    @Published var uiImage: UIImage?
    
    internal func getImage(url: URL?) async throws {
        guard let url = url else {
            self.uiImage = UIImage()
            throw AZCachedAsyncImageServiceError.invalidUrl
        }
        let urlString = url.absoluteString
        if let uiImage = ImageCache.shared[urlString] {
            self.uiImage = uiImage
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let uiImage = UIImage(data: data)
                ImageCache.shared[urlString] = uiImage
                self.uiImage = uiImage
            } catch {
                throw error
            }
        }
    }
    
    private func eagerLoadImage(url: URL) async throws {
        let urlString = url.absoluteString
        guard ImageCache.shared[urlString] == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let uiImage = UIImage(data: data)
            ImageCache.shared[urlString] = uiImage
        } catch {
            throw error
        }
    }
    
    public func eagerLoadImages(from urlStrings: [String]) async throws {
        let urls = urlStrings.compactMap { URL(string: $0) }
        await withThrowingTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try await self.eagerLoadImage(url: url)
                }
            }
        }
    }
}
