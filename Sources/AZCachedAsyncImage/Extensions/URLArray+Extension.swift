//
//  URLArray+Extension.swift
//  
//
//  Created by Adam Zarn on 9/10/22.
//

import Foundation

extension Array where Element == URL {
    var combinedFileSizesInBytes: UInt64 {
        return reduce(0) { $0 + $1.fileSizeInBytes }
    }
    
    var combinedFileSizesInBytesString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(combinedFileSizesInBytes), countStyle: .file)
    }
}
