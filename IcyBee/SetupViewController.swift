//
//  SetupViewController.swift
//  IcyBee
//
//  Created by six on 12/14/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class SetupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

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
