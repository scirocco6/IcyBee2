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
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.keyboardWillShow(_:)),
                                               name: NSNotification.Name(rawValue: "UIKeyboardWillShowNotification"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.keyboardWillHide(_:)),
                                               name: NSNotification.Name(rawValue: "UIKeyboardWillHideNotification"),
                                               object: nil)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIKeyboardWillShowNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIKeyboardWillHideNotification"), object: nil)
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
    
// Mark - UITextFieldDelegate
    func keyboardWillShow(_ notification: Notification) {
    }
    
    func keyboardWillHide(_ notification: Notification) {
    }
    
//    - (void)keyboardWillShow:(NSNotification *) notification {
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    
//    CGRect aRect = self.view.frame;
//    
//    aRect.size.height -= keyboardSize.height;
//    if (!CGRectContainsPoint(aRect, inputTextField.frame.origin) ) {
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(scrollView.contentInset.top, 0.0, keyboardSize.height, 0.0);
//    scrollView.contentInset = contentInsets;
//    scrollView.scrollIndicatorInsets = contentInsets;
//    }
//    }
//    
//    
//    - (void) keyboardWillHide:(NSNotification *) notification {
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(scrollView.contentInset.top, 0.0, 0.0, 0.0);
//    scrollView.contentInset = contentInsets;
//    scrollView.scrollIndicatorInsets = contentInsets;
//    }
//    
//    -(BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [inputTextField resignFirstResponder];
//    
//    if([[inputTextField text] length]) {
//    [[IcbConnection sharedInstance] processInput: [inputTextField text]];
//    [inputTextField setText:@""];
//    }
//    
//    return YES;
//    }
}

