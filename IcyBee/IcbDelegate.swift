//
//  IcbDelegate.swift
//  IcyBee
//
//  Created by six on 11/22/16.
//  Copyright © 2016 six. All rights reserved.
//

import Foundation
import CoreData
import AudioToolbox
import IcbKit
import RegExKit


class IcbDelegate: FNProtocolDelegate {
    public static let icbController = IcbDelegate()

    // Core Data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var messages: NSEntityDescription
    var managedContext: NSManagedObjectContext
    
    let courierNormal = UIFont(name: "Courier", size: 16)

    init() {
        managedContext = appDelegate.persistentContainer.viewContext
        messages =  NSEntityDescription.entity(forEntityName: "ChatMessage", in:managedContext)!
    }
    
    func connect() {
        icbConnect(delegate: self)
    }
    
    // MARK: - User Input
    func parseUserInput(_ input: String) {
        if input.hasPrefix("/beep")   { beep(input) }
        else if input.hasPrefix("/m") { privateMessage(input) }
        else if input.hasPrefix("/g") { joinGroup(input) }
//        else if input.hasPrefix("/w") { whoCommand(input) }
        else {icbSendOpenMessage(input)}
    }
    
    // iOS input methods will sometimes add an extra whitespace to the end
    func joinGroup(_ inputString: String) {
        let regex = RXRegularExpression(pattern: "^\\/g\\s+(\\S+)\\s?$", matching: inputString)
        
        if regex.matched {
            let target = regex.captures[0]
            icbJoinGroup(target)
        }
        else {
            userTextErrorMessage("USAGE: /g groupname\n")
        }
    }
    
    func privateMessage(_ inputString: String) {
        let regex = RXRegularExpression(pattern: "^\\/m\\s+(\\S+)\\s+(.+)", matching: inputString)
        
        if regex.captured == 2 {
            let target = regex.captures[0]
            let message = regex.captures[1]
            icbSendPrivateMessage(message, to: target)
        }
        else {
            userTextErrorMessage("USAGE: /m nickname message\n")
        }
    }
    
    func beep(_ inputString: String) {
        let regex = RXRegularExpression(pattern: "^\\/beep\\s+(\\S+)\\s?$", matching: inputString)
        
        if regex.matched {
            let target = regex.captures[0]
            icbSendBeep(to: target)
        }
        else {
            userTextErrorMessage("USAGE: /beep nickname\n")
        }
    }
    
    // Mark: - Output
    func handleStatusMessage(from: String, text: String) {
        if text.hasPrefix("You are now in group ") {setIcbGroup(text)}
        else {
            displayStatusMessage(from: from, text: text)
        }
    }
    
    func handlePresenceMessage(from: String, text: String) {
        let regex = RXRegularExpression(pattern: "^(\\S+)\\s+", matching: text)
        
        if regex.matched {
            let user = regex.captures[0]
            if from == "Arrive" {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "FNUserArrived"), object: nil, userInfo: ["user": user])
            }
            else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "FNUserDeparted"), object: nil, userInfo: ["user": user])
            }
        }
    }
    
    func handleArriveMessage(from: String, text: String) {
        
    }
    
    func setIcbGroup(_ text: String) {
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
    
    func displayStatusMessage(from: String, text: String) {
        let from = NSAttributedString(string:"[=\(from)=]")
        let text = NSAttributedString(string: text)
    
        displayMessage(sender: from, text: text)
    }
    
    func displayMessage(sender: NSAttributedString, text: NSAttributedString) {
        let sender = NSMutableAttributedString(attributedString: sender)
        let text = NSMutableAttributedString(attributedString: text)
        
        sender.addAttributes([NSFontAttributeName: courierNormal!], range: NSMakeRange(0, sender.length))
        text.addAttributes([NSFontAttributeName: courierNormal!], range: NSMakeRange(0, text.length))
        
        //message.addAttributes([NSForegroundColorAttributeName: UIColor.blue], range: NSMakeRange(0, message.length))
        
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "FNNewMessage"),
            object: nil,
            userInfo: ["from": sender, "text": text])
    }
    
    func userTextErrorMessage(_ errorMessage: String) {
        let sender = NSMutableAttributedString(string: "[=IcyBee=]")
        let text   = NSMutableAttributedString(string: errorMessage)
        
        sender.addAttributes([NSFontAttributeName: courierNormal!], range: NSMakeRange(0, sender.length))
        text.addAttributes([NSFontAttributeName: courierNormal!], range: NSMakeRange(0, text.length))
        text.addAttributes([NSForegroundColorAttributeName: UIColor.red], range: NSMakeRange(0, text.length))

        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "FNNewMessage"),
            object: nil,
            userInfo: ["from": sender, "text": text])
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
            // usually we are already logged in elsewhere and need to drop or change username
            // we may have a bad password
            // or have tried to join a group we aren't allowed to join
            //
        }
    }
    
    // by enumerating the possible senders then switching on the enumeration we guarantee that we parse an
    // inclusive list
    func icbReceiveStatusMessage(from: String, text: String) {
        enum senders: String {
            case status = "Status"
            case topic  = "Topic"
            case depart = "Depart"
            case arrive = "Arrive"
        }
        
        if let sender = senders(rawValue: from) {
            switch sender {
            case .status: handleStatusMessage(from: from, text: text)
            case .topic:  handleTopicMessage(from: from, text: text)
            case .arrive, .depart: handlePresenceMessage(from: from, text: text)
            }
        }
        else {
            displayStatusMessage(from: from, text: text)
        }
        
    }

    func icbReceiveOpenMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<\(from)>")
        let text = NSAttributedString(string: text)
        
        displayMessage(sender: from, text: text)
    }
    
    func icbReceivePersonalMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<*\(from)*>")
        let text = NSAttributedString(string: text)
        
        displayMessage(sender: from, text: text)
    }
    
    func icbReceiveImportantMessage(from: String, text: String) {
        let from = NSAttributedString(string:"<=\(from)=>")
        let text = NSAttributedString(string: text)
        
        displayMessage(sender: from, text: text)
    }
    
    func icbReceiveErrorMessage(text: String) {
        let from = NSAttributedString(string:"[=Error=]")
        let text = NSAttributedString(string: text)
        
        displayMessage(sender: from, text: text)
    }
    
    func icbReceiveBeepMessage(from: String) {
        let sender = NSAttributedString(string:"[=Beep!=]")
        let text = NSAttributedString(string: " \(from) has sent you a beep!")
        
        // http://iphonedevwiki.net/index.php/AudioServices
        // AudioServicesPlayAlertSound(1054)
        // AudioServicesPlayAlertSound(1106)
        AudioServicesPlayAlertSound(1013)
        
        displayMessage(sender: sender, text: text)
    }
    
    func icbReceiveGenericOutput(text: String) {
        let sender = NSMutableAttributedString(string: "")
        let text   = NSAttributedString(string: text)
        
        displayMessage(sender: sender, text: text)
    }
    
    func icbWhoComplete() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNWhoUpdated"), object: nil, userInfo: ["whoResults": self.icbWhoResults])
        })
        
        if let topic = icbWhoResults.groups[icbChannel]?.topic {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
    }
}
