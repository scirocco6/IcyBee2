//
//  SplitViewController.swift
//  IcyBee
//
//  Created by six on 12/14/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.maximumPrimaryColumnWidth = 200
        let navigationController = self.viewControllers[self.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = self.displayModeButtonItem
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)

        let preferences = UserDefaults.standard

        if preferences.string(forKey: "channel_preference")  == nil ||
            preferences.string(forKey: "nick_preference") == nil ||
            preferences.string(forKey: "pass_preference") == nil {
            
            performSegue(withIdentifier: "showSetup", sender: nil)
        }
        else {
            // TODO: - IcbDelegate.icbController.connect() really doesn't belong here
            IcbDelegate.icbController.connect()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
