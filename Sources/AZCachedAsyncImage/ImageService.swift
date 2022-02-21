//
//  ImageService.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

public enum ImageServiceError: Error {
    case invalidUrl
}

@MainActor
class ImageService: ObservableObject {
    @Published var uiImage: UIImage?
    
    func getImage(url: URL?) async throws {
        guard let url = url else {
            self.uiImage = UIImage()
            throw ImageServiceError.invalidUrl
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
}
