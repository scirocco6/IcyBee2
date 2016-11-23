//
//  ChatViewController.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {
    @IBOutlet var titleBar: UINavigationItem?
    @IBOutlet var textView: UITextView?
    
    let emptyString  = NSMutableAttributedString(string: "")
    let spaceString  = NSMutableAttributedString(string: " ")
    let returnString = NSMutableAttributedString(string: "\n")

    var messageString = NSMutableAttributedString(string: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // subscribe to topic change messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.updateTopic(_:)),
                                               name: NSNotification.Name(rawValue: "FNTopicUpdated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.addMessage(_:)),
                                               name: NSNotification.Name(rawValue: "FNNewMessage"),
                                               object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTopic(_ notification: Notification) {
        if let topic = notification.userInfo?["topic"] as? String {
            titleBar?.title = topic == "(None)" ? "" : topic // don't show (None) as topic blank instead
        }
    }
    
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
        textView?.textStorage.append(newMessage)
        

        let bottom = NSMakeRange((textView?.text.characters.count)! - 1, 1)
        textView?.scrollRangeToVisible(bottom)
    }
}

