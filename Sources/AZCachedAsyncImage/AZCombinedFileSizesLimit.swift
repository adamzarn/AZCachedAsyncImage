//
//  AZCombinedFileSizesLimit.swift
//  
//
//  Created by Adam Zarn on 9/10/22.
//

import Foundation

public enum AZCombinedFileSizesLimit {
    case kilobytes(_ count: UInt64)
    case megabytes(_ count: UInt64)
    case gigabytes(_ count: UInt64)
    
    var asNumberOfBytes: UInt64 {
        switch self {
        case .kilobytes(let count): return count * 1_000
        case .megabytes(let count): return count * 1_000_000
        case .gigabytes(let count): return count * 1_000_000_000
        }
    }
}
