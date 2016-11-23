//
//  FNProtocolDelegate.swift
//  IcbKit
//
//  Created by six on 11/22/16.
//  Copyright © 2016 six. All rights reserved.
//

import Foundation

// MARK: - FNProtocolDelegate

public protocol FNProtocolDelegate: FNProtocol {
    var icbClientID: String {get}
    var icbChannel:  String {get}
    var icbNickname: String {get set}
    var icbPassword: String {get}
    var icbServer:   String {get}
    var icbPort:     Int    {get}
    
    func icbReceiveOpenMessage(from: String, text: String)
    func icbReceivePersonalMessage(from: String, text: String)
    func icbReceiveImportantMessage(from: String, text: String)
    func icbReceiveStatusMessage(from: String, text: String)
    func icbReceiveBeepMessage(from: String)
    func icbReceiveErrorMessage(text: String)
    func icbReceiveGenericOutput(text: String)
    
    func icbLoginComplete(result: Bool)
    func icbWhoComplete()
}

public extension FNProtocolDelegate {
    var icbWhoResults: FNWhoResults {return FNConnection.connectionManager.whoResults}
    
    func icbWhoComplete() {}
    
    func icbLoginComplete(result: Bool) {}
    
    func icbConnect(delegate: FNProtocolDelegate) {
        FNConnection.connectionManager.connect(delegate: delegate)
    }
}
