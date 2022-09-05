//
//  AZImageCache.swift
//  AZCachedAsyncImage
//
//  Created by Adam Zarn on 2/21/22.
//

import UIKit

class AZImageCache: NSCache<NSString, UIImage> {
    static let shared = AZImageCache()
  
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

