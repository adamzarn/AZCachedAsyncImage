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
        return absoluteString.components(separatedBy: invalidCharacters).joined(separator: "")
    }
}
