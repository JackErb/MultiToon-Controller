//
//  ViewController.swift
//  KeyCloner
//
//  Created by Jack Erb on 7/20/16.
//  Copyright © 2016 Jack Erb. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    static var sharedController: ViewController!
    
    // Allow ViewController to be a first responder (i.e. respond to key/mouse events)
    override var acceptsFirstResponder: Bool { return true }
    
    var keySendMode = KeySendMode.mirror
    
    // Information of the applications this program will be sending info to.
    // Used for Mirror-Mode.
    var ttApplications = [ApplicationInfo]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // These two variable are used for Multi-Mode. 
    var toontownApplication1: ApplicationInfo? {
        didSet {
            tableView.reloadData()
        }
    }
    var toontownApplication2: ApplicationInfo? {
        didSet {
            tableView.reloadData()
        }
    }
    
    // Is searching for applications
    var sendKeyStrokes = false {
        willSet {
            playAndStopButton.state = newValue ? 1 : 0
            
            guard let keyEventDelegate = keyEventDelegate as? KeyEventSender else {
                return
            }
        
            for key in keyEventDelegate.keyboard.keys {
                keyEventDelegate.postKeyEvent(withKeyCode: key.keyCode, isDown: newValue, sender: self, postNoMatterWhat: true)
                keyEventDelegate.keyboard.handleKeyEvent(key.keyCode, isDown: true)
            }
        }
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var playAndStopButton: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    
    var keyEventDelegate: KeyEventDelegate?
    
    override func viewDidLoad() {        
        // Finish singleton model. Part of a hacky piece of code to make this class the first responder. See AppDelegate.
        ViewController.sharedController = self
    
        keyEventDelegate = KeyEventSender()
        
        // AXIsProcessTrusted must be true to monitor key strokes while in the background.
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
 
            // Sends user to System Preferences -> Accessibility to give this program permission
            AXIsProcessTrustedWithOptions(options as CFDictionary?)
        }
        
        if !AXIsProcessTrusted() {
            // TO DO: Alert user in some way that program will be limited in functionality.
        }
        
        
        // Global monitor for event KeyDown. This triggers if a key is pushed down while in the background.
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.keyDown(with:))
        
        // Global monitor for event KeyUp. This triggers if a key is released while in the background.
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp, handler: self.keyUp(with:))
        
        // Global monitor for event FlagsChanged. This triggers if a key is released while in the background.
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: self.flagsChanged(with:))
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.target = self
        tableView.doubleAction = #selector(ViewController.tableViewDoubleClick(_:))
        tableView.resignFirstResponder()
    }
    
    func animateProgressIndicator(_ bool: Bool) {
        if bool {
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(nil)
        } else {
            progressIndicator.isHidden = true
            progressIndicator.stopAnimation(nil)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        keyEventDelegate?.keyDown(event, sender: self)
    }
    
    override func keyUp(with event: NSEvent) {
        keyEventDelegate?.keyUp(event, sender: self)
    }
    
    override func flagsChanged(with event: NSEvent) {
        keyEventDelegate?.flagsChanged(event, sender: self)
    }
    
    // Refresh toontown application list
    @IBAction func refreshButtonAction(_ sender: NSButton) {
        searchForToontownApplications(sender: self)
    }
    
    // Either stop or start key event sending
    @IBAction func playAndStopButtonAction(_ sender: NSButton) {
        sendKeyStrokes = sender.state == 1 ? true : false
    }
    
    @IBAction func targetButtonAction(_ sender: AnyObject) {
        // Remove self as observer in case the user has already pressed this button.
        // This is just so the event isn't being observed twice.
        NSWorkspace.shared().notificationCenter.removeObserver(self)
        
        NSWorkspace.shared().notificationCenter.addObserver(self, selector: #selector(self.frontmostApplicationDidChange(_:)), name: NSNotification.Name.NSWorkspaceDidActivateApplication, object: nil)
        
        animateProgressIndicator(true)
    }
    
    @IBAction func keySendModeToggleButton(_ sender: AnyObject) {
        switch keySendMode {
        case .multi:
            keySendMode = .mirror
            tableView.reloadData()
        case .mirror:
            keySendMode = .multi
            
            searchForToontownApplications(sender: self)
            tableView.reloadData()
        }
    }
    
    func frontmostApplicationDidChange(_ notification: Notification) {
        let psn = getProcessSerialNumberOfFrontmostApplication()
        
        ttApplications.append(ApplicationInfo(application: NSWorkspace.shared().frontmostApplication!, psn: psn))
        
        NSWorkspace.shared().notificationCenter.removeObserver(self)
        animateProgressIndicator(false)

    }
}


extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keySendMode == .mirror ? ttApplications.count : 2
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.make(withIdentifier: "ApplicationsCell", owner: nil) as? NSTableCellView {
            if keySendMode == .mirror {
                cell.textField?.stringValue = ttApplications[row].application.localizedName ?? "Unnamed"
                cell.imageView?.image = ttApplications[row].activated ? NSImage(named: "thumbs-up") : NSImage(named: "thumbs-down")
            } else {
                var app: ApplicationInfo? = nil
                if row == 0 { app = toontownApplication1 }
                else if row == 1 { app = toontownApplication2 }
                
                cell.textField?.stringValue = app?.application.localizedName ?? "Not found"
                cell.imageView?.image = app?.activated ?? false ?  NSImage(named: "thumbs-up") : NSImage(named: "thumbs-down")
            }

            return cell
        }
        return nil
    }
    
    
    // Not part of the protocol but used to deal with `NSTableView` events
    func tableViewDoubleClick(_ sender: AnyObject) {
        if keySendMode == .multi { return }
        
        guard tableView.selectedRow >= 0 else {
            return
        }
        
        ttApplications[tableView.selectedRow].activated = !ttApplications[tableView.selectedRow].activated
    }
}
