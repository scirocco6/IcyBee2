//
//  MessageView.swift
//  IcyBee
//
//  Created by six on 11/30/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class MessageView: UITextView {

    let spaceString  = NSMutableAttributedString(string: " ")
    let returnString = NSMutableAttributedString(string: "\n")

    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageView.addMessage(_:)),
                                               name: NSNotification.Name(rawValue: "FNNewMessage"),
                                               object: nil)
    }

    // Mark - ICB Output
    func addMessage(_ notification: Notification) {
        let newMessage = NSMutableAttributedString(string: "")
        if let from = notification.userInfo?["from"] as? NSAttributedString {
            newMessage.append(from)
            newMessage.append(spaceString)
        }
        if let text = notification.userInfo?["text"] as? NSAttributedString {
            newMessage.append(text)
        }
        
        newMessage.append(returnString)
        textStorage.append(newMessage)
        
        scrollToBottom()
    }
    
    func scrollToBottom() {
        let bottom = NSMakeRange(text.characters.count - 1, 1)
        scrollRangeToVisible(bottom)
    }
    
}
