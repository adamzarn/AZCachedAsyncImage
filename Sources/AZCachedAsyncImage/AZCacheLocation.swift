//
//  AZCacheLocation.swift
//  
//
//  Created by Adam Zarn on 9/4/22.
//

import Foundation

public enum AZCacheLocation {
    case memory
    case fileSystem(directory: URL?)
}
