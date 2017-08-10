//
//  ChatViewController.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleBar: UINavigationItem!
    @IBOutlet var inputLine: UITextField!
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!
    
    let emptyString   = NSMutableAttributedString(string: "")
    var messageString = NSMutableAttributedString(string: "")
    
    var hasExternalKeyboard = false
    
// Mark - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // needed to enable automatic row height
        tableView.estimatedRowHeight = 10.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // subscribe to topic change messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.updateTopic(_:)),
                                               name: NSNotification.Name(rawValue: "FNTopicUpdated"),
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


    
// Mark - Topic updates
    func updateTopic(_ notification: Notification) {
        if let topic = notification.userInfo?["topic"] as? String {
            titleBar?.title = topic == "(None)" ? "" : topic // don't show (None) as topic blank instead
        }
    }
    
// Mark - Keyboard handling
    func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}

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

        bottomLayoutConstraint.constant = (keyboardFrame?.origin.y)! >= UIScreen.main.bounds.size.height ? 0.0 : keyboardHeight
        
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
    
// Mark - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if hasExternalKeyboard == false {textField.resignFirstResponder()}
        
        if textField.text != "" {
            // Send the new message to the icbController, which will handle it like any other ICB message.
            let sender = NSMutableAttributedString(string: "")
            let text   = NSAttributedString(string: textField.text!)
            
            IcbDelegate.icbController.displayMessage(sender: sender, text: text)

            IcbDelegate.icbController.parseUserInput(textField.text!)
            textField.text = ""
        }
        
        return true
    }
    
    // MARK: - Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = ["Good morning", "1\n2\n3\n4", "What\nTime\nIs\nLove?\n\noh yeah\n\noh yeah"]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Chat Message", for: indexPath) as! MessageCell
        cell.message?.text = content[indexPath.row]
        
        return cell
    }
}

