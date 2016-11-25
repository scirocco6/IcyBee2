//
//  MasterViewController.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import IcbKit

class MasterViewController: UITableViewController {
    @IBOutlet var titleBar: UINavigationItem?
    
    var chatViewController: ChatViewController? = nil
    var objects = [Any]()

    var currentGroupName: String? {
        didSet{
            titleBar?.title = currentGroupName
        }
    }
    var currentGroup: FNGroup?
    var usersInGroup: [String]?
    var whoResults: FNWhoResults?

    // Mark - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.navigationItem.leftBarButtonItem = self.editButtonItem

//        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
//        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.chatViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ChatViewController
        }

        // subscribe to who updates
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MasterViewController.updateWho(_:)),
                                               name: NSNotification.Name(rawValue: "FNWhoUpdated"),
                                               object: nil)

        // subscribe to group change messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MasterViewController.updateGroup(_:)),
                                               name: NSNotification.Name(rawValue: "FNGroupUpdated"),
                                               object: nil)
        
        // subscribe to user arrival messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MasterViewController.userArrived(_:)),
                                               name: NSNotification.Name(rawValue: "FNUserArrived"),
                                               object: nil)
        
        // subscribe to user departure messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MasterViewController.userDeparted(_:)),
                                               name: NSNotification.Name(rawValue: "FNUserDeparted"),
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        // unsubscribe from who updates
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "FNWhoUpdated"), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "FNGroupUpdated"), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let controller = (segue.destination as! UINavigationController).topViewController as! ChatViewController
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentGroup == nil || usersInGroup == nil {return 0}
        return usersInGroup!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NickNameCell

        if let moderator = currentGroup?.moderator {
            if let nickName = usersInGroup?[indexPath.row] {
                cell.moderatorIndicator?.text = nickName == moderator ? "m" : ""
                cell.nickNameLabel?.text = nickName
            }
        }
        
        return cell
    }

    // Mark: User interaction
    
    // MARK: - ICB
    func updateWho(_ notification: Notification) {
        guard
            let results    = notification.userInfo?["whoResults"] as! FNWhoResults?,
            let groupName  = currentGroupName,
            let nameSet    = results.usersByGroup[groupName]
        else {return}

        whoResults   = results
        currentGroup = whoResults?.groups[groupName]
        usersInGroup = Array(nameSet).sorted()
        
        self.tableView.reloadData()
        
        if let topic = currentGroup?.topic {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "FNTopicUpdated"), object: nil, userInfo: ["topic": topic])
        }
    }
    
    func updateGroup(_ notification: Notification) {
        if let groupName = notification.userInfo?["groupName"] as? String {
            currentGroupName = groupName
            currentGroup = whoResults?.groups[groupName]
            
            // should prolly fire a who command
            self.tableView.reloadData()
        }
    }
    
    func userArrived(_ notification: Notification) {
        guard
            let userName = notification.userInfo?["user"] as? String,
            let group = currentGroupName
        else {
            IcbDelegate.icbController.icbGlobalWho()
            return
        }
        
        _ = whoResults?.usersByGroup[group]?.insert(userName)
        whoResults?.usersByNickname[userName]?.group = group
        
        updateNameSet()
    }
    
    func userDeparted(_ notification: Notification) {
        guard
            let userName = notification.userInfo?["user"] as? String,
            let group = currentGroupName
        else {
            IcbDelegate.icbController.icbGlobalWho()
            return
        }
        
        _ = whoResults?.usersByGroup[group]?.remove(userName)
        whoResults?.usersByNickname[userName]?.group = "" // we have no idea where they went so just blank it
                
        updateNameSet()
    }
    
    func updateNameSet() {
        guard
            let group = currentGroupName,
            let nameSet = whoResults?.usersByGroup[group]
        else {
            IcbDelegate.icbController.icbGlobalWho()
            return
        }
        
        usersInGroup = Array(nameSet.sorted())
        self.tableView.reloadData()
    }
}

