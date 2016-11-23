
//
//  IcbProtocol.swift
//  IcbKit
//
//  Created by six on 10/17/16.
//  Copyright © 2016 six. All rights reserved.
//

import Foundation
import RegExKit

public enum FNState {
    case disconnected
    case connected
    case loggingIn
    case loggedIn
    case whoing
}

// MARK: - FNProtocol

public protocol FNProtocol: FNPacketProtocol {
    var FNDelegate: FNProtocolDelegate? {get}
}

public extension FNProtocol {
// MARK: - receive messages

    func processPacket( _ packet: String) {
        var packet = packet
        
        let rawType = packet.remove(at: packet.startIndex)
        if let type = FNMessageType(rawValue: rawType) {
            let contents = packet.components(separatedBy: "\(UnicodeScalar(1)!)")
            let message  = FNMessage(type: type, contents: contents)
            
            switch type {
            case .level: return
            case .nop:   return

            case .login: processLoginSuccessMessage()
            case .open, .personal, .important, .status: processMessage(message, type: type)
            case .beep: processBeepMessage(message)
            case .error: processErrorMessage(message)
            case .output: processCommandOutput(message)

            default: return
            }
        }
        else {
            // TODO: - Error handling for unknown packet type.  VERY unlikely to ever happen
        }
    }
    
    func processLoginSuccessMessage() {
        FNConnection.connectionManager.state = .loggedIn
        
        FNDelegate?.icbLoginComplete(result: true)
    }
    
    func processCommandOutput(_ message: FNMessage) {
        if let subType = message.contents?[0] {
            switch subType {
            case "co": processGenericCommandOutput(message)
            case "eg": return // was never implemented on servers :(
            case "ec": return // was never implemented on servers :(
            case "wh": return // we'll let the client do it's own formatting thank you
            case "wl": processWhoLine(message)
            default: return
            }
        }
    }
    
    func processGenericCommandOutput(_ message: FNMessage) {
        if let message = message.contents?.last {
            if message == "" || message == " " {return} // we'll let the client do its own formatting, if you please
            if FNConnection.connectionManager.state != .whoing {
                FNDelegate?.icbReceiveGenericOutput(text: message)
            }
            else {
                if message.hasPrefix("Group:") { processWhoGroup(message) }
                else if message.hasPrefix("Total:") { processEndOfWho() }
            }
        }
    }
    
    func processWhoGroup(_ message: String) {        
        let regex = RXRegularExpression(pattern: "^Group:\\s+(\\S+)\\s+\\\u{28}(\\w+)\\)\\s+Mod:\\s+(\\S+)\\s+Topic:\\s+(.+)", matching: message)
        if regex.captured == 4 {
            
            let name        = regex.captures[0]
            let permissions = regex.captures[1]
            let moderator   = regex.captures[2]
            let topic       = regex.captures[3]
            
            let perms = Array(permissions.characters)
            let moderation = FNModeration(rawValue: perms[0])
            let visibility = FNVisibility(rawValue: perms[1])
            let volume     = FNVolume(rawValue: perms[2])
            
            let modName:   String? = moderator == "(none)" ? nil : moderator
            let topicText: String? = topic     == "(none)" ? nil : topic
            
            let group = FNGroup(
                name:       name,
                moderation: moderation!,
                visibility: visibility!,
                volume:     volume!,
                moderator:  modName,
                topic:      topicText
            )
            
            FNConnection.connectionManager.addGroupToCache(group)
        }
    }
    
    func processEndOfWho() {
        FNConnection.connectionManager.state = .loggedIn
        FNConnection.connectionManager.whoLock.signal()
        FNDelegate?.icbWhoComplete()
    }

    func processWhoLine(_ message: FNMessage) {
        if let contents = message.contents {
            let nickname = contents[2]
            let idle     = TimeInterval(contents[3])
            let signOnT  = TimeInterval(contents[5])
            let userName = contents[6]
            let hostName = contents[7]
            
            let signOnDate = Date(timeIntervalSince1970: signOnT!)
            
            let user = FNUser(
                nickname: nickname,
                idle:     idle!,
                signOn:   signOnDate,
                username: userName,
                hostname: hostName,
                group:    FNConnection.connectionManager.currentWhoGroup
            )
            
            FNConnection.connectionManager.addUserToCache(user)
        }
    }
    
    func processMessage(_ message: FNMessage, type: FNMessageType) {
        guard
            message.contents?.count == 2,
            let from = message.contents?.first,
            let text = message.contents?.last
        else {return} // TODO: - Error handling for ill formed message packet
        
        switch type {
            case .open:      FNDelegate?.icbReceiveOpenMessage(from: from, text: text)
            case .personal:  FNDelegate?.icbReceivePersonalMessage(from: from, text: text)
            case .important: FNDelegate?.icbReceiveImportantMessage(from: from, text: text)
            case .status:    processStatusMessage(from: from, text: text)

            default: return // unknown message type is unlikely in a 30 year old protocol
        }
    }
    
    func processStatusMessage(from: String, text: String) {
        if from == "No-Pass" {return} // this is handled by IcbKit now, not client
        FNDelegate?.icbReceiveStatusMessage(from: from, text: text)
    }
    
    func processErrorMessage(_ message: FNMessage) {
        guard
            message.contents?.count == 1,
            let text = message.contents?.first
            else {return} // TODO: - Error handling for ill formed message packet
        
        FNDelegate?.icbReceiveErrorMessage(text: text)
    }
    
    func processBeepMessage(_ message: FNMessage) {
        guard
            message.contents?.count == 1,
            let from = message.contents?.first
            else {return} // TODO: - Error handling for ill formed message packet
    
        FNDelegate?.icbReceiveBeepMessage(from: from)
    }
    
// MARK: - send messages
    func sendLogin(clientID: String, nickname: String, channel: String, password: String) {
        FNConnection.connectionManager.state = .loggingIn
        let loginPacket = createLoginPacket(clientID, nickname: nickname, channel: channel, password: password)
        FNConnection.connectionManager.sendPacket(loginPacket)
    }
    
    public func icbSendOpenMessage(_ message: String) {
        let messagePacket = createOpenMessagePacket(message)
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
    
    public func icbSendPrivateMessage(_ message: String, to: String) {
        let messagePacket = createPrivateMessagePacket(to: to, message: message)
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
    
    public func icbSendBeep(to: String) {
        let messagePacket = createBeepPacket(to: to)
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
    
    public func icbJoinGroup(_ group: String) {
        let messagePacket = createGroupPacket(group)
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
    
    public func icbGlobalWho() {
        if FNConnection.connectionManager.state == .whoing {return} // do not start a new who if already whoing
        _ = FNConnection.connectionManager.whoLock.wait(timeout: .distantFuture)
        FNConnection.connectionManager.state = .whoing

        FNConnection.connectionManager.clearWhoCache()
        let messagePacket = createGlobalGroupListPacket()
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
    
    public func icbGroupWho(_ group: String) {
        if FNConnection.connectionManager.state == .whoing {return} // do not start a new who if already whoing

        let messagePacket = createLocalGroupListPacket(group)
        FNConnection.connectionManager.sendPacket(messagePacket)
    }
}

