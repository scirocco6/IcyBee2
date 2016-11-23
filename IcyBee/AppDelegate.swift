//
//  AppDelegate.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import IcbKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, FNProtocolDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        icbConnect(delegate: self)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        
//
// should we allow an empty message area?  ie a discarded controller
// the code below is from the original template and most likely we will just discard this
//        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
//        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
//        if topAsDetailController.detailItem == nil {
//            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//            return true
//        }
        
        return false
    }
    
    // MARK: - shared delegate
    //static var sharedDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
            icbGlobalWho()
        }
    }

    func icbReceiveOpenMessage(from: String, text: String) {}
    func icbReceivePersonalMessage(from: String, text: String) {}
    func icbReceiveImportantMessage(from: String, text: String) {}

    func icbReceiveStatusMessage(from: String, text: String) {
        if from == "Status"{
            if let range = text.range(of: "You are now in group ") {
                icbChannel = text.substring(from: range.upperBound)
                if let range = icbChannel.range(of: " as moderator") {
                    icbChannel.removeSubrange(range)
                }
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "FNGroupUpdated"), object: nil, userInfo: ["groupName": self.icbChannel])
                })
            }
        }
    }

    func icbReceiveBeepMessage(from: String) {}
    func icbReceiveErrorMessage(text: String) {}
    func icbReceiveGenericOutput(text: String) {}
    
    func icbWhoComplete() {
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNWhoUpdated"), object: nil, userInfo: ["whoResults": self.icbWhoResults])
        })
    }
}

