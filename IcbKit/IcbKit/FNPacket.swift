//
//  IcbPacket.swift
//  IcyBee2
//
//  Created by six on 11/9/14.
//  Copyright (c) 2014 The Home For Obsolete Technology. All rights reserved.
//
//
// protocol/packet description at http://www.icb.net/_jrudd/icb/protocol.html
//
import Foundation

public enum FNMessageType: Character {
    case login      = "a"
    case open       = "b"
    case personal   = "c"
    case status     = "d"
    case error      = "e"
    case important  = "f"
    case exit       = "g"
    case command    = "h"
    case output     = "i"
    case level      = "j"
    case beep       = "k"
    case ping       = "l"
    case pong       = "m"
    case nop        = "n"
}

public struct FNMessage {
    public let type:       FNMessageType
    public let contents:   Array<String>?
}

public struct FNPacket {
    var packet = ""
    var size = 0;
    
    init(type: FNMessageType, parameters: String...) {
        packet += String(type.rawValue)
        
        var seperator = ""
        for parameter in parameters {
            packet += seperator + parameter
            seperator = "\(UnicodeScalar(1)!)"
        }
        
        size = packet.lengthOfBytes(using: String.Encoding.utf8)
        packet = "\(UnicodeScalar(size)!)" + packet   // NOT counting the size byte
        size += 1 // include the size byte we just added when transmitting
    }
}

public protocol FNPacketProtocol {}

public extension FNPacketProtocol {
    func createLoginPacket(_ clientID: String, nickname: String, channel: String,  password: String) -> FNPacket {
        return FNPacket(type: .login, parameters: clientID, nickname, channel, "login", password)
    }
    
    func createOpenMessagePacket(_ message: String) -> FNPacket {
        return FNPacket(type: .open, parameters: message)
    }
    
    // there isn't an actual send private message packet in icb.  Instead we create a 
    // server command packet with the m command and send that
    func createPrivateMessagePacket(to: String, message: String) -> FNPacket {
        return FNPacket(type: .command, parameters: "m\u{1}\(to) \(message)\0")
    }
    
    // default.icb.net doesn't handle beep packets use command packet beep instead
    func createBeepPacket(to: String) -> FNPacket {
        return FNPacket(type: .command, parameters: "beep\u{1}\(to)\0")
    }
    
    func createGroupPacket(_ group: String) -> FNPacket {
        return FNPacket(type: .command, parameters: "g\u{1}\(group)\0")
    }
    
    func createGlobalGroupListPacket() -> FNPacket {
        return FNPacket(type: .command, parameters: "w\u{1}")
    }
    
    func createLocalGroupListPacket(_ group: String) -> FNPacket {
        return FNPacket(type: .command, parameters: "w\u{1}\(group)\0")
    }
    
    func createJoinGroupPacket(_ group: String) -> FNPacket {
        return FNPacket(type: .command, parameters: "g", group)
    }
    
    func createNoOpPacket() -> FNPacket {
        return FNPacket(type: .nop)
    }
}
