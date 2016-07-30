//
//  Delay.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/20/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

// Simple subclass the denies first responder ability.
class NSTableViewNoFirstResponder: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }
}