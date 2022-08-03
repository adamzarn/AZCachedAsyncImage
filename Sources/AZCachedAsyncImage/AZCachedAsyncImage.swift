//
//  AZCachedAsyncImage.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

/// A view that asynchronously loads, caches, and displays an image.
public struct AZCachedAsyncImage<I: View, P: View>: View {
    @StateObject var imageService = AZCachedAsyncImageService()
    let url: URL?
    let size: CGSize?
    var content: (Image) -> I
    var placeholder: () -> P
    
    /// - Parameters:
    ///     - url: The remote URL of the image.
    ///     - size: The CGSize to resize the returned image to.
    ///     - content: Callback to modify the Image that displays the returned image.
    ///     - placeholder: Callback to provide the View that will display while the image is loading.
    public init(url: URL?,
                size: CGSize? = nil,
                content: @escaping (Image) -> I,
                placeholder: @escaping () -> P) {
        self.url = url
        self.size = size
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        ZStack {
            if let uiImage = imageService.uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task {
            do {
                try await imageService.getImage(url: url, size: size)
            } catch {
                print(error)
            }
        }
    }
}
