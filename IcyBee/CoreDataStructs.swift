//
//  MessagesProtocol.swift
//  IcyBee
//
//  Created by six on 12/20/16.
//  Copyright © 2016 six. All rights reserved.
//

import UIKit
import CoreData

public enum DataTypes {
    case messages
    case people
}

let thing = DataTypes.messages

struct CoreData {
    var context: NSManagedObjectContext
    var entity:  NSEntityDescription
    
    init(_ type: DataTypes) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        context = appDelegate.persistentContainer.viewContext
        entity  =  NSEntityDescription.entity(forEntityName: String(describing: type), in:context)!
    }
}
