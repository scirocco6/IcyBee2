//
//  SetupViewController.swift
//  IcyBee
//
//  Created by six on 12/14/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import IcbKit

class SetupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if (UserDefaults.standard.string(forKey: "nick_preferences") != nil) {
            IcbDelegate.icbController.connect()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        IcbDelegate.icbController.connect()
    }
}
