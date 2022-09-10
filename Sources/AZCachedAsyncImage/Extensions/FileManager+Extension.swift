//
//  FileManager+Extension.swift
//  
//
//  Created by Adam Zarn on 9/4/22.
//

import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static var fileNamePrefix: String { "AZCachedAsyncImage" }
    
    static func getAllURLs(in directory: URL, withPrefix prefix: String? = nil) -> [URL] {
        var urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        if let prefix = prefix {
            urls = urls?.filter { $0.lastPathComponent.hasPrefix(prefix) }
        }
        return urls ?? []
    }
    
    static func deleteOldestFile(in directory: URL, withPrefix prefix: String? = nil) throws {
        guard let oldestFileURL = getAllURLs(in: directory, withPrefix: prefix).sorted(by: {
            $0.creationDate ?? Date() < $1.creationDate ?? Date()
        }).first else { return }
        try FileManager.default.removeItem(at: oldestFileURL)
    }
}
