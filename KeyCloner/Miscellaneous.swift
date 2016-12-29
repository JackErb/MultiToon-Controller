//
//  Delay.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/20/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

// Simple subclass the denies first responder ability.
class NSTableViewNoFirstResponder: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }
}
