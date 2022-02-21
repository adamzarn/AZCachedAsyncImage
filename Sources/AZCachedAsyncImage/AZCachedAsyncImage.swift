//
//  AZCachedAsyncImage.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import SwiftUI

public struct AZCachedAsyncImage<I: View, P: View>: View {
    @StateObject var imageService = ImageService()
    let url: URL?
    var content: (Image) -> I
    var placeholder: () -> P
    
    public init(url: URL?,
         content: @escaping (Image) -> I,
         placeholder: @escaping () -> P) {
        self.url = url
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
                try await imageService.getImage(url: url)
            } catch {
                print(error)
            }
        }
    }
}
