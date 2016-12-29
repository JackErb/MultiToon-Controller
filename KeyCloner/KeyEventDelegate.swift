//
//  KeyEventDelegate.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/21/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

protocol KeyEventDelegate {
    // The keyboard lists all keys that are currently down and should be updated whenever keyDown or keyUp is called.
    var keyboard: Keyboard { get }
    
    func keyDown(_ event: NSEvent, sender: ViewController)
    func keyUp(_ event: NSEvent, sender: ViewController)
    func flagsChanged(_ event: NSEvent, sender: ViewController)
}

enum KeySendMode {
    case multi, mirror
}

// This class sends key events to target applications specified in the sender
class KeyEventSender: KeyEventDelegate {
    let keyboard = Keyboard()
    
    // Checks to see if the specified key is a hard-coded hot key. Returns true if it was.
    // TO DO: Allow customization of hot keys and also add more for more functionality.
    func checkHotkeys(_ event: NSEvent, sender: ViewController) -> Bool {
        let key = Key(value: event.keyCode)
        
        switch key {
        case .f5:
            searchForToontownApplications(sender: sender)
            return true
        case .grave:
            // The animation is just to provide some visual feedback to the user so they know the button press did something.
            sender.animateProgressIndicator(true)
            delay (0.25) {
                sender.animateProgressIndicator(false)
            }
            
            sender.sendKeyStrokes = true
            NSRunningApplication.current().activate(options: .activateIgnoringOtherApps)
            
            // This is to delete the ` key that was pressed in the application
            postKeyEvent(withKeyCode: Key.delete.keyCode, isDown: true, sender: sender, postNoMatterWhat: true)
            delay (0.1) { self.postKeyEvent(withKeyCode: Key.delete.keyCode, isDown: false, sender: sender, postNoMatterWhat: true) }
            return true
        case .forwardDelete:
            if sender.tableView.selectedRow >= 0 && sender.keySendMode == .mirror {
                sender.ttApplications.remove(at: sender.tableView.selectedRow)
            }
            return true
        default:
            return false
        }
    }
    
    func keyDown(_ event: NSEvent, sender: ViewController) {
        // Pressed keys which are hotKeys are not sent to the target application
        if !checkHotkeys(event, sender: sender) {
            postKeyEvent(withKeyCode: event.keyCode, isDown: true, sender: sender)
        }
    }
    
    func keyUp(_ event: NSEvent, sender: ViewController) {
        postKeyEvent(withKeyCode: event.keyCode, isDown: false, sender: sender)
    }
    
    func flagsChanged(_ event: NSEvent, sender: ViewController) {
        if sender.keySendMode == .mirror {
            postKeyEvent(withKeyCode: Key.count.keyCode, isDown: false, sender: sender)
        } else {
            /*let key = getModifierKey(event)
            print(key)
            postKeyEvent(withKeyCode: key?.keyCode ?? Key.Count.keyCode, isDown: key != nil ? !keyboard.keys.contains(key!) : false, sender: sender)*/
        }
        
        // TO DO: Allow customization of this toggle key
        let isCommandKey = Bool(event.modifierFlags.rawValue & NSEventModifierFlags.command.rawValue as NSNumber)
        if isCommandKey {
            sender.sendKeyStrokes = !sender.sendKeyStrokes
        }
    }
    
    /*func getModifierKey(event: NSEvent) -> Key? {
        func isKey(modifierFlag: NSEventModifierFlags) -> Bool {
            return Bool(event.modifierFlags.rawValue & modifierFlag.rawValue)
        }
        
        let keyToModifierFlag: [(key: Key, flag: NSEventModifierFlags)] = [(.LeftControl, .ControlKeyMask),
                                                                           (.LeftOption, .AlternateKeyMask),
                                                                           (.LeftShift, .ShiftKeyMask)]
        
        for (key, flag) in keyToModifierFlag {
            if isKey(flag) {
                return key
            }
        }
        
        return nil
    }*/
    
    // Posts key events to all of the sender's ttApplications
    func postKeyEvent(withKeyCode keyCode: UInt16, isDown: Bool, sender: ViewController, postNoMatterWhat: Bool = false) {
        keyboard.handleKeyEvent(keyCode, isDown: isDown)
        
        // If the KeyCloner application is in the front and it is allowed to send key strokes then send the key strokes.
        // If this is not true but the parameter `postNoMatterWhat` is, then post them anyways.
        // `postNoMatterWhat` is used in the `ViewController`'s `sendKeyStrokes` setter. Even if sendKeyStrokes is set to false,
        // it needs to post the events to properly disconnect from the application.
        guard (sender.sendKeyStrokes && NSWorkspace.shared().frontmostApplication == NSRunningApplication.current()) || postNoMatterWhat else {
            return
        }
        
        let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: isDown)
        
        if sender.keySendMode == .mirror {
            // Post the key event to all toontown applications
            for (index,var application) in sender.ttApplications.enumerated() {
                // Toontown application has been terminated. Remove it from the list.
                if application.application.isTerminated {
                    sender.ttApplications.remove(at: index)
                    return
                }
                
                // Application has been deactivated by the user -- Don't send key events.
                if !application.activated { continue }
                
                // Convert the process serial number to an UnsafeMutablePointer<Void>
                let address = withUnsafeMutablePointer(to: &application.psn) {UnsafeMutableRawPointer($0)}
                
                keyEvent?.postToPSN(processSerialNumber: address)
            }
        } else {
            // In .Multi mode
            guard var app1 = sender.toontownApplication1, var app2 = sender.toontownApplication2 else {
                // Alert user that something went wrong
                return
            }
            
            let address1 = withUnsafeMutablePointer(to: &app1.psn) {UnsafeMutableRawPointer($0)}
            let address2 = withUnsafeMutablePointer(to: &app2.psn) {UnsafeMutableRawPointer($0)}
            
            let key = Key(value: keyCode)
            switch key {
            // Events posted to the first application
            case .up, .left, .down, .right:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: key.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address1)
            case .period:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.leftControl.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address1)
                
            // Events posted to the second application
            case .w:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.up.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address2)
            case .a:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.left.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address2)
            case .s:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.down.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address2)
            case .d:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.right.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address2)
            case .f:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.leftControl.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address2)
                
            // Events posted to both applications
            case .space:
                let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: Key.forwardDelete.keyCode, keyDown: isDown)
                keyEvent?.postToPSN(processSerialNumber: address1)
                keyEvent?.postToPSN(processSerialNumber: address2)
            default: break
            }
        }
        
    }
}
