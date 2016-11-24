//
//  ChatViewController.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var titleBar: UINavigationItem?
    @IBOutlet var textView: UITextView?
    @IBOutlet var inputLine: UITextField?
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint?
    
    let emptyString  = NSMutableAttributedString(string: "")
    let spaceString  = NSMutableAttributedString(string: " ")
    let returnString = NSMutableAttributedString(string: "\n")

    var messageString = NSMutableAttributedString(string: "")
    var hasExternalKeyboard = false
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame,
                                               object: nil)
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateTopic(_ notification: Notification) {
        if let topic = notification.userInfo?["topic"] as? String {
            titleBar?.title = topic == "(None)" ? "" : topic // don't show (None) as topic blank instead
        }
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
        textView?.textStorage.append(newMessage)
        

        let bottom = NSMakeRange((textView?.text.characters.count)! - 1, 1)
        textView?.scrollRangeToVisible(bottom)
    }

    
// Mark - Keyboard handling
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            

            let keyboard = self.view.convert(keyboardFrame!, from: self.view.window)
            let height   = self.view.frame.size.height;
            
            var keyboardHeight = height - keyboard.origin.y
            if ((keyboard.origin.y + keyboard.size.height) > height) {
                hasExternalKeyboard = true
            }
            else {
                hasExternalKeyboard = false
                keyboardHeight = (keyboardFrame?.size.height) ?? 0.0
            }
            
            bottomLayoutConstraint?.constant = (keyboardFrame?.origin.y)! >= UIScreen.main.bounds.size.height ? 0.0 : keyboardHeight

            let duration             = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveNumber =  userInfo[UIKeyboardAnimationCurveUserInfoKey]    as? NSNumber
            let animationCurveRaw    =  animationCurveNumber?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve       =  UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
// Mark - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if hasExternalKeyboard == false {textField.resignFirstResponder()}
        
        if textField.text != "" {
            textView?.text.append(textField.text!)
            textView?.text.append("\n")
            IcbDelegate.icbController.parseUserInput(textField.text!)
            textField.text = ""
        }
        
        return true
    }
}

