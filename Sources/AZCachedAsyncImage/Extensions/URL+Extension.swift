//
//  URL+Extension.swift
//  
//
//  Created by Adam Zarn on 9/4/22.
//

import Foundation

extension URL {
    var asValidFileName: String {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)
        return FileManager.fileNamePrefix + "-" + absoluteString.components(separatedBy: invalidCharacters).joined(separator: "")
    }
    
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    var fileSizeInBytes: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }

    var fileSizeInBytesString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSizeInBytes), countStyle: .file)
    }

    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}
