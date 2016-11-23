//
//  RXRegularExpressions.swift
//  RegExKit
//
//  Created by six on 10/23/16.
//  Copyright © 2016 six. All rights reserved.
//

import Foundation

public struct RXRegularExpression {
    public var pattern: String?
    public var regex: NSRegularExpression?
    public var matched = false
    public var captures = [""]

    public init(pattern: String) {
        self.pattern = nil
        regex = nil
        matched = false
        captures = [""]
        
        regex = try? NSRegularExpression(pattern: pattern, options: [])
        if regex != nil {self.pattern = pattern}
    }
    
    public init(pattern: String, matching: String) {
        self.init(pattern: pattern)
        match(matching)
    }
    
    public mutating func match(_ string: String) {
        captures = [""]
        matched = false
        
        let end = (string as NSString).length
        guard
            let matches = regex?.matches(in: string, range: NSRange(location: 0, length: end)),
            matches.count == 1
        else {return}
        
        matched = true
        captures = []
        let match = matches[0]
        for capture in 1..<match.numberOfRanges {
            captures.append((string as NSString).substring(with: match.rangeAt(capture)))
        }
    }
    
    public var captured:Int {
        return captures.count
    }
}
