//
//  ToontownApplication.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/21/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

struct ApplicationInfo {
    let application: NSRunningApplication
    var psn: ProcessSerialNumber
    
    var activated = true
    
    init (application: NSRunningApplication, psn: ProcessSerialNumber) {
        self.application = application
        self.psn = psn
    }
}

func getProcessSerialNumberOfFrontmostApplication() -> ProcessSerialNumber {
    let low = UInt32(NSWorkspace.sharedWorkspace().activeApplication()!["NSApplicationProcessSerialNumberLow"] as! Int)
    let high = UInt32(NSWorkspace.sharedWorkspace().activeApplication()!["NSApplicationProcessSerialNumberHigh"] as! Int)
    return ProcessSerialNumber(highLongOfPSN: high, lowLongOfPSN: low)
}


func searchForToontownApplications(sender sender: ViewController) {
    sender.animateProgressIndicator(true)
    sender.sendKeyStrokes = false
    
    var ttAppInfo = [ApplicationInfo]()
    var toontownApplications = [NSRunningApplication]()
    for app in NSWorkspace.sharedWorkspace().runningApplications {
        if app.localizedName == "Toontown Rewritten" && app.bundleIdentifier == nil {
            toontownApplications.append(app)
            
            // Multi sends to a max of two applications
            if sender.keySendMode == .Multi && toontownApplications.count == 2 { break }
        }
    }
    
    guard toontownApplications.count > 0 else {
        if sender.keySendMode == .Multi {
            let alert = NSAlert()
            alert.addButtonWithTitle("Ok")
            alert.messageText = "Two Toontown applications could not be found, so key events will stop being sent. Make sure that both applications are open then click the refresh button."
            
            alert.beginSheetModalForWindow(sender.view.window!) { response in }

        }
        
        sender.animateProgressIndicator(false)
        return
    }
    
    var iterator = toontownApplications.generate()
    
    var getInfo: (NSRunningApplication -> Void)!
    getInfo = { (app: NSRunningApplication) in
        app.activateWithOptions(.ActivateIgnoringOtherApps)
        
        // Closure is delayed because the application is not activated on the main thread, and it may take some time for it
        // to do so. If the application is currently doing something intensive (i.e. loading content), it may take awhile.
        delay (0.2) {
            if app.active {
                ttAppInfo.append(ApplicationInfo(application: app, psn: getProcessSerialNumberOfFrontmostApplication()))
            }
            
            if let nextApp = iterator.next() {
                getInfo(nextApp)
            } else {
                // We've iterated through all the toontown applications. Bring this application back to the front.
                sender.animateProgressIndicator(false)
                sender.sendKeyStrokes = true
                
                if sender.keySendMode == .Multi {
                    if ttAppInfo.count < 2 {
                        // Display error that two applications couldn't be found
                        let alert = NSAlert()
                        alert.addButtonWithTitle("Ok")
                        alert.messageText = "Two Toontown applications could not be found. Make sure that both applications are open then click the refresh button."
                        alert.informativeText = "Key events will not be sent until a second application is found."
                        
                        alert.beginSheetModalForWindow(sender.view.window!) { response in }
                    } else {
                        sender.toontownApplication1 = ttAppInfo[0]
                        sender.toontownApplication2 = ttAppInfo[1]
                    }
                } else {
                    sender.ttApplications = ttAppInfo
                }
                
                NSRunningApplication.currentApplication().activateWithOptions(.ActivateIgnoringOtherApps)
            }
        }
    }
    
    getInfo(iterator.next()!)
}