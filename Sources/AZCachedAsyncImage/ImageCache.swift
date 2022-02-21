//
//  ImageCache.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import UIKit

class ImageCache: NSCache<NSString, UIImage> {
    static let shared = ImageCache()
  
    subscript(key: String) -> UIImage? {
        get {
            return object(forKey: NSString(string: key))
        }
        set {
            if let newValue = newValue {
                setObject(newValue, forKey: NSString(string: key))
            } else {
                removeObject(forKey: NSString(string: key))
            }
        }
    }
}

