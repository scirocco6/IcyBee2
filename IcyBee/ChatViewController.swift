//
//  ChatViewController.swift
//  IcyBee
//
//  Created by six on 11/21/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import CoreData

// MARK: - TODO
// too many delegates.  Break this up
class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var titleBar: UINavigationItem!
    @IBOutlet var inputLine: UITextField!
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!
    
    let emptyString   = NSMutableAttributedString(string: "")
    var messageString = NSMutableAttributedString(string: "")
    
    var hasExternalKeyboard = false
    
    fileprivate let dataContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer

    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<ChatMessage> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
// Mark - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // needed to enable automatic row height
        tableView.estimatedRowHeight = 1.1 // estimate to minimum height to force as much hugging as we can get
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
        
        // subscribe to topic change messages
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ChatViewController.updateTopic(_:)),
                                               name: NSNotification.Name(rawValue: "FNTopicUpdated"),
                                               object: nil)
        
        // start the fetcherResultsController
        // Mark - TODO
        // again there is no real logical way to handle complete failure of 
        // CoreData.  Not sure how it could fail this far in but if it did there
        // isn't much real recourse I can think of
        do {
            try self.fetchedResultsController.performFetch()
        }
        catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
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
        guard let messages = fetchedResultsController.fetchedObjects else { return 0 }
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCell(withIdentifier: "Chat Message", for: indexPath) as! MessageCell
        let message = fetchedResultsController.object(at: indexPath)

        // only add the sender if different from the sender in the prior cell
        var sender = message.sender!
        if indexPath[1] != 0 {
            let oldMessage = fetchedResultsController.object(at: [0, indexPath[1] - 1])
            if oldMessage.sender! == sender && oldMessage.type == message.type {
                sender = ""
            }
        }
        
        if cell.sender?.frame.width != 0 {
            cell.sender?.text  = sender
            cell.message?.text = message.text!
        }
        else {
            cell.message?.text = "\(sender) \(message.text!)"
        }
        return cell
    }
    
    // Mark - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.tableView.endUpdates()
        if self.tableView.numberOfRows(inSection: 0) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: self.tableView.numberOfRows(inSection: 0) - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?){

        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
        case .move: break
        case .update:
            self.tableView.deleteRows(at: [indexPath!], with: .fade)
            self.tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
//
// Currently the view is one giant section.  Should that change this is the update function for sections
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
//                    didChange sectionInfo: NSFetchedResultsSectionInfo,
//                    atSectionIndex sectionIndex: Int,
//                    for type: NSFetchedResultsChangeType){
//    }
}

