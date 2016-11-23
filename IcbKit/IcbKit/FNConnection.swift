//
//  icbConnection.swift
//  IcyBee2
//
//  Created by six on 11/9/14.
//  Copyright (c) 2014 The Home For Obsolete Technology. All rights reserved.
//

import Foundation
//
//  icbConnection.swift
//  IcyBee2
//
//  Created by six on 11/9/14.
//  Copyright (c) 2014 The Home For Obsolete Technology. All rights reserved.
//
//
// protocol/packet description at http://www.icb.net/_jrudd/icb/protocol.html
//

// TODO: - need a queue of commands to prevent responce interleaving
// ie
//
// 1 user requests a global who
// 2 user requests a channel who
// need to detect completion of 1 then state change then handle 2
class FNConnection: NSObject, StreamDelegate, FNProtocol {
    var state = FNState.disconnected
    var currentWhoGroup = ""
    let whoLock = DispatchSemaphore(value: 1)

    var _groups = [String: FNGroup]()
    var _usersByNickname = [String: FNUser]()
    var _usersByGroup = [String: Set<String>]()
    
    var inputStream:  InputStream?
    var outputStream: OutputStream?

    var FNDelegate: FNProtocolDelegate?
    
    var whoResults: FNWhoResults {
        _ = FNConnection.connectionManager.whoLock.wait(timeout: .distantFuture)
        
        let results = FNWhoResults(
            groups: _groups,
            usersByNickname: _usersByNickname,
            usersByGroup: _usersByGroup
        )

        FNConnection.connectionManager.whoLock.signal()
        
        return results
    }
    
// MARK: - connectionManager
    class var connectionManager: FNConnection {
        struct Singleton {
            static let instance = FNConnection()
        }
        
        return Singleton.instance
    }
    

// MARK: - FNProtocol
    public func connect(delegate: FNProtocolDelegate) {
        Stream.getStreamsToHost(withName: delegate.icbServer, port: delegate.icbPort, inputStream: &inputStream, outputStream: &outputStream)
        
        FNDelegate = delegate
        inputStream!.delegate  = self
        outputStream!.delegate = self
        
        inputStream!.schedule(in: RunLoop.current,  forMode: RunLoopMode.defaultRunLoopMode)
        outputStream!.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        
        inputStream!.open()
        outputStream!.open()
    }
    
    public func receivePacket() {
        struct rawPacket { // while fun to write, I think this whole struct thing is kinna screwball, especially given we are in a singleton class
            static var totalBytes     = 0
            static var remainingBytes = 0
            static var buffer         = UnsafeMutablePointer<UInt8>.allocate(capacity: 258) // yes 258, icb is a weird weird protocol
            static var current        = buffer
            
            static func start() {                     // setup the packet to start reading in data
                totalBytes     = Int(buffer.pointee) // the first byte of the buffer is the size
                remainingBytes = totalBytes
                current        = buffer             // set the current position to the begining of the buffer
            }
            
            static func add(_ count: Int) {
                remainingBytes -= count
                current = current.advanced(by: count)
            }
            
            static func done() -> Bool {
                return remainingBytes == 0 ? true : false
            }
            
            static func string() -> String {
                current.pointee = 0
                return String(cString: UnsafePointer(buffer))
            }
        }

        var length: Int?
        
        if (rawPacket.remainingBytes > 0) {
            length = inputStream?.read(rawPacket.current, maxLength: rawPacket.remainingBytes)
            if length! > 0 {
                rawPacket.add(length!)

                if rawPacket.done() {
                    processPacket(rawPacket.string())
                }
            }
        }
        else {
            length = inputStream?.read(rawPacket.buffer, maxLength: 1) // the first byte of a packet is the number of bytes remaining to be read
            if length != nil {
                rawPacket.start()
            }
        }
    }
    
    public func sendPacket(_ packet: FNPacket) {
        outputStream?.write(packet.packet, maxLength: packet.size)
    }
    
    public func clearWhoCache() {
        currentWhoGroup = ""
        _groups = [String: FNGroup]()
    }
    
    public func addGroupToCache(_ group: FNGroup) {
        let groupName = group.name

        currentWhoGroup = groupName
        _groups[groupName] = group
    }
    
    public func addUserToCache(_ user: FNUser) {
        let name = user.nickname
        
        _usersByNickname[name] = user
        if _usersByGroup[currentWhoGroup] != nil {
            _usersByGroup[currentWhoGroup]?.insert(name)
        }
        else {
            let names: Set<String> = [name]
            _usersByGroup[currentWhoGroup] = names
        }
    }
    
// MARK: - NSStreamDelegate
    public func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
            case Stream.Event.openCompleted:
                state = .connected
            
            case Stream.Event.hasSpaceAvailable:
                if(state == .connected) {
                    sendLogin(clientID: FNDelegate!.icbClientID, nickname: FNDelegate!.icbNickname, channel: FNDelegate!.icbChannel, password: FNDelegate!.icbPassword)
                }

            case Stream.Event.hasBytesAvailable:
                receivePacket()
            
            case Stream.Event():
                NSLog("NSStreamEvent.None")
            
            case Stream.Event.endEncountered:
                NSLog("NSStreamEvent.EndEncountered")
            
            case Stream.Event.errorOccurred:
                NSLog("NSStreamEvent.ErrorOccurred")
            
            default:
                NSLog("Unknown networking event occured")
        }
    }
}
