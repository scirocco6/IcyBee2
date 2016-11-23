//
//  IcbDelegate.swift
//  IcyBee
//
//  Created by six on 11/22/16.
//  Copyright © 2016 six. All rights reserved.
//

import Foundation
import AudioToolbox
import IcbKit

class IcbDelegate: FNProtocolDelegate {
    public static let icbController = IcbDelegate()

    func connect() {
        icbConnect(delegate: self)
    }
    
    // MARK: - FNProtocol
    
    var FNDelegate: FNProtocolDelegate?
    
    var icbClientID = "iOSBee"
    var icbChannel  = "IcyBee"
    var icbNickname = "iOSBee6"
    var icbPassword = "1234"
    var icbServer   = "default.icb.net"
    var icbPort     = 7326
    var whoCommand  = false
    var whoView     = false
    
    func icbLoginComplete(result: Bool) {
        if result {
            // yay we logged in
        }
        else {
            // boo something went wrong
            // usually we are already logged in else where and need to drop or change username
            // we may have bad password
            // or have tried to join a group we aren't allowed to join
        }
    }
    
    // by enumerating the possible senders then switching on the enumeration we guarantee that we parse an
    // inclusive list
    func icbReceiveStatusMessage(from: String, text: String) {
        enum senders: String {
            case status = "Status"
            case topic  = "Topic"
        }
        
        if let sender = senders(rawValue: from) {
            switch sender {
            case .status: handleStatusMessage(from: from, text: text)
            case .topic:  handleTopicMessage(from: from, text: text)
            }
        }
        else {
            let from = NSAttributedString(string:"[=\(from)=]")
            let text = NSAttributedString(string: text)
            
            assembleAndShowMessage(sender: from, text: text)
        }
    }
    

    func icbReceiveOpenMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<\(from)>")
        let text = NSAttributedString(string: text)
        
        assembleAndShowMessage(sender: from, text: text)
    }
    
    func icbReceivePersonalMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<*\(from)*>")
        let text = NSAttributedString(string: text)
        
        assembleAndShowMessage(sender: from, text: text)
    }
    
    func icbReceiveImportantMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<=\(from)=>")
        let text = NSAttributedString(string: text)
        
        assembleAndShowMessage(sender: from, text: text)
    }
    
    func icbReceiveErrorMessage(text: String) {
        let from = NSAttributedString(string:"[=Error=]")
        let text = NSAttributedString(string: text)
        
        assembleAndShowMessage(sender: from, text: text)
    }
    
    func icbReceiveBeepMessage(from: String) {
        let sender = NSAttributedString(string:"[=Beep!=]")
        let text = NSAttributedString(string: " \(from) has sent you a beep!")
        
        // http://iphonedevwiki.net/index.php/AudioServices
        // AudioServicesPlayAlertSound(1054)
        // AudioServicesPlayAlertSound(1106)
        AudioServicesPlayAlertSound(1013)
        
        assembleAndShowMessage(sender: sender, text: text)
    }
    
    func icbReceiveGenericOutput(text: String) {
        let sender = NSMutableAttributedString(string: "")
        let text   = NSAttributedString(string: text)
        
        assembleAndShowMessage(sender: sender, text: text)
    }
    
    func icbWhoComplete() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNWhoUpdated"), object: nil, userInfo: ["whoResults": self.icbWhoResults])
        })
        
        if let topic = icbWhoResults.groups[icbChannel]?.topic {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
    }
    
    func handleStatusMessage(from: String, text: String) {
        if let range = text.range(of: "You are now in group ") {
            icbGlobalWho() // update all who information
            
            icbChannel = text.substring(from: range.upperBound)
            if let range = icbChannel.range(of: " as moderator") {
                icbChannel.removeSubrange(range)
            }
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "FNGroupUpdated"), object: nil, userInfo: ["groupName": self.icbChannel])
            })
        }
    }
    
    func handleTopicMessage(from: String, text: String) {
        if let range = text.range(of: "changed the topic to \"") {
            let topic = String(text.substring(from: range.upperBound).characters.dropLast())
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
    }
    
    func assembleAndShowMessage(sender: NSAttributedString, text: NSAttributedString) {
        let message = NSMutableAttributedString()
        message.append(sender)
        message.append(NSAttributedString(string: " "))
        message.append(text)
        
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "FNNewMessage"),
            object: nil,
            userInfo: ["from": sender, "text": text])
    }
}
