//
//  FNUserAndGroup.swift
//  IcbKit
//
//  Created by six on 10/25/16.
//  Copyright © 2016 six. All rights reserved.
//

// information for enums can be found by typeing "/help groups" in cicb
import Foundation


public struct FNUser {
    public var nickname = ""
    public var idle     = TimeInterval()
    public var signOn   = Date()
    public var username = ""
    public var hostname = ""
    public var group: String
}

public enum FNModeration: Character {
    case `public`   = "p"
    case moderated  = "m"
    case restricted = "r"
}

public enum FNVisibility: Character {
    case visible   = "v"
    case secret    = "s"
    case invisible = "i"
}

public enum FNVolume: Character {
    case quiet  = "q"
    case normal = "n"
    case loud   = "l"
}

public struct FNGroup {
    public var name = ""
    public var moderation = FNModeration.public
    public var visibility = FNVisibility.visible
    public var volume = FNVolume.normal
    public var moderator: String?
    public var topic: String?
}

public struct FNWhoResults {
    public var groups: [String: FNGroup]
    public var usersByNickname: [String: FNUser]
    public var usersByGroup: [String: Set<String>]
}
