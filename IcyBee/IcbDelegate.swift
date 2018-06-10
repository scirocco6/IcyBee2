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

    let preferences   = UserDefaults.standard
//    let bodyFont = UIFont(name: "Courier", size: 16)
    let bodyFont = UIFont.preferredFont(forTextStyle: .body)
    
    // Core Data
    let dataContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    var managedContext: NSManagedObjectContext
    var messages: NSEntityDescription

    init() {
        managedContext = dataContainer.viewContext
        
        // TODO: - I don't know how it could ever fail here but handle better               --v
        messages = NSEntityDescription.entity(forEntityName: "ChatMessage", in:managedContext)!
    }
    
    // preference strings are created from default values in the bundle.  Still I don't like so many
    // !s in the code.  Is there any way the strings could not be there?
    // Is there any logical thing we could do if the preference strings aren't there?
    func connect() {
        icbClientID = "IcyBee2"
        icbServer   = preferences.string(forKey: "server_preference")!
        // TODO: - Convert this to an int
        icbPort     = Int(preferences.string(forKey: "port_preference")!)!
        icbChannel  = preferences.string(forKey: "channel_preference")!
        icbNickname = preferences.string(forKey: "nick_preference")!
        icbPassword = preferences.string(forKey: "pass_preference")!
        
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
            icbReceiveUsageMessage("USAGE: /g groupname\n")
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
            icbReceiveUsageMessage("USAGE: /m nickname message\n")
        }
    }
    
    func beep(_ inputString: String) {
        let regex = RXRegularExpression(pattern: "^\\/beep\\s+(\\S+)\\s?$", matching: inputString)
        
        if regex.matched {
            let target = regex.captures[0]
            icbSendBeep(to: target)
        }
        else {
            icbReceiveUsageMessage("USAGE: /beep nickname\n")
        }
    }
    
    // Mark: - Output
    func handleStatusMessage(from: String, text: String) {
        if text.hasPrefix("You are now in group ") {
            setIcbGroup(text)
        }
        else {
            icbReceiveGenericStatusMessage(from: from, text: text)
        }
    }
    
    func handlePresenceMessage(from: String, text: String) {
        let regex = RXRegularExpression(pattern: "^(\\S+)\\s+", matching: text)
        
        if regex.matched {
            let user = regex.captures[0]
            if from == "Arrive" || from == "Sign-on" {
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
            
            //icbChannel = text.substring(from: range.upperBound)
            icbChannel = String(text[range.upperBound...])
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
            // let topic = String(text.substring(from: range.upperBound).characters.dropLast())
            let topic = String(text[range.upperBound...].dropLast())
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
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
            case status  = "Status"
            case topic   = "Topic"
            case depart  = "Depart"
            case arrive  = "Arrive"
            case signon  = "Sign-on"
            case signoff = "Sign-off"
        }
        
        if let sender = senders(rawValue: from) {
            switch sender {
            case .status: handleStatusMessage(from: from, text: text)
            case .topic:  handleTopicMessage(from: from, text: text)
            case .arrive, .depart, .signon, .signoff: handlePresenceMessage(from: from, text: text)
            }
        }
        else {
            icbReceiveGenericStatusMessage(from: from, text: text)
        }
    }
    
    func icbReceiveGenericStatusMessage(from: String, text: String) {
        let nickname         = NSMutableAttributedString(string:"[=\(from)=]")
        let messageText      = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.open, from: from, text: text, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    func icbReceiveOpenMessage(from: String, text: String) {
        let nickname         = NSMutableAttributedString(string:"<\(from)>")
        let messageText = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.open, from: from, text: text, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    
    func icbReceivePersonalMessage(from: String, text: String) {
        let nickname         = NSMutableAttributedString(string:"<*\(from)*>")
        let messageText      = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.personal, from: from, text: text, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    func icbReceiveImportantMessage(from: String, text: String) {
        let nickname         = NSMutableAttributedString(string:"<=\(from)=>")
        let messageText      = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.important, from: from, text: text, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    func icbReceiveErrorMessage(text: String) {
        let nickname         = NSMutableAttributedString(string:"[=Error=]")
        let messageText      = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.error, from: "Error", text: text, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    func icbReceiveBeepMessage(from: String) {
        let text             = "\(from) has sent you a beep!"
        let nickname         = NSMutableAttributedString(string:"[=\(from)=]")
        let messageText      = NSMutableAttributedString(string: text)
        
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        
        addMessageToStore(type: FNMessageType.beep, from: from, text: text, decoratedLabel: nickname, decoratedMessage: messageText)
        
        // http://iphonedevwiki.net/index.php/AudioServices
        // AudioServicesPlayAlertSound(1054)
        // AudioServicesPlayAlertSound(1106)
        AudioServicesPlayAlertSound(1013)
    }
    
    func icbReceiveGenericOutput(text: String) {
        let messageText = NSMutableAttributedString(string: text)

        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        addMessageToStore(type: FNMessageType.error, from: "Server", text: text, decoratedMessage: messageText)
    }

    func icbReceiveUsageMessage(_ errorMessage: String) {
        let from = "IcyBee"

        let nickname = NSMutableAttributedString(string:"[=\(from)=]")
        nickname.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, nickname.length))

        let messageText = NSMutableAttributedString(string: errorMessage)
        messageText.addAttributes([NSAttributedStringKey.font: bodyFont], range: NSMakeRange(0, messageText.length))
        messageText.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.red], range: NSMakeRange(0, messageText.length))

        addMessageToStore(type: FNMessageType.beep, from: from, text: errorMessage, decoratedLabel: nickname, decoratedMessage: messageText)
    }
    
    func icbWhoComplete() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNWhoUpdated"), object: nil, userInfo: ["whoResults": self.icbWhoResults])
        })
        
        if let topic = icbWhoResults.groups[icbChannel]?.topic {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
    }
    
    // MARK: - Core Data
    
    func addMessageToStore(type: FNMessageType, from: String, text: String, decoratedMessage: NSAttributedString) {
        let chatMessage = ChatMessage(context: managedContext)
        chatMessage.type = String(type.rawValue)
        chatMessage.timeStamp = Date()

        chatMessage.sender = from
        chatMessage.text = text
        chatMessage.decoratedMessage = decoratedMessage

        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    func addMessageToStore(type: FNMessageType, from: String, text: String, decoratedLabel: NSAttributedString, decoratedMessage: NSAttributedString) {
        let chatMessage = ChatMessage(context: managedContext)
        chatMessage.type = String(type.rawValue)
        chatMessage.timeStamp = Date()
        
        chatMessage.sender = from
        chatMessage.text = text
        chatMessage.decoratedMessage = decoratedMessage
        chatMessage.decoratedLabel = decoratedLabel
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }

}
