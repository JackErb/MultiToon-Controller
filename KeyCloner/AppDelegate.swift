//
//  AppDelegate.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/20/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // This is pretty hacky but I don't understand Cocoa and didn't want to take time to learn it.
        // Sets the ViewController as the first responder of the window so that it gets key events.
        ViewController.sharedController.view.window!.makeFirstResponder(ViewController.sharedController)
        ViewController.sharedController.view.window!.level = Int(CGWindowLevelForKey(.maximumWindow))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

