//
//  SetupViewController.swift
//  IcyBee
//
//  Created by six on 12/14/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import IcbKit

class SetupViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var nickname: UITextField!
    @IBOutlet var channel:  UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var confirm:  UITextField!
    
    @IBOutlet var problems: UITextView!

    let preferences = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (preferences.string(forKey: "nick_preference") != nil) {
            IcbDelegate.icbController.connect()
        }
        
        if let preferedChannel = preferences.string(forKey: "channel_preference") {
            channel.text = preferedChannel
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.returnKeyType == .next) {
            let nextField = textField.superview?.viewWithTag(textField.tag + 1) as! UITextField
            // nextField.becomeFirstResponder  // this no longer works in iOS 8+
            nextField.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.0)
        }
        else if (textField.returnKeyType == .done) {
            // textField.resignFirstResponder // double ugh, see above
            textField.perform(#selector(resignFirstResponder), with: nil, afterDelay: 0.0)
        }

        return true
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == "joinIcb") {return processSetupDetails()}
        return true
    }
    
    func processSetupDetails() -> Bool {
        var errorString = ""
        var setupComplete = true
        
        if (nickname.text == "" || channel.text == "" || password.text == "" || confirm.text == "") {
            let placeholderString = NSAttributedString(string: "required", attributes: [NSForegroundColorAttributeName: UIColor.red])
            
            nickname.attributedPlaceholder = placeholderString
            channel.attributedPlaceholder  = placeholderString
            password.attributedPlaceholder = placeholderString
            confirm.attributedPlaceholder  = placeholderString
            
            errorString = "Please fill in all required fields."
            setupComplete = false
        }

        if password.text?.isEmpty == false && confirm.text?.isEmpty == false && password.text != confirm.text {
            if errorString != "" {
                errorString += "\n"
            }
            
            errorString += "The password and confirmation fields do not match."
            setupComplete = false
        }
        
        if setupComplete == false {
            problems.text = errorString
            problems.isHidden = false
        }
        
        return setupComplete
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        IcbDelegate.icbController.connect()
    }
}
