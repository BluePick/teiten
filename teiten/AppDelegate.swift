//
//  AppDelegate.swift
//  teiten
//
//  Created by nakajijapan on 12/21/14.
//  Copyright (c) 2014 net.nakajijapan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    // kill process when application closed window
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    
    @IBAction func captureImageMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.sharedApplication().mainWindow else {
            return
        }
        
        guard let captureViewController = mainWindow.contentViewController as? CaptureViewController else {
            return
        }

        captureViewController.captureImage()
    }
    
    
    @IBAction func createMovieMenuItemDidSelect(sender: AnyObject) {
        
        guard let mainWindow = NSApplication.sharedApplication().mainWindow else {
            return
        }
        
        guard let captureViewController = mainWindow.contentViewController as? CaptureViewController else {
            return
        }
        
        captureViewController.createMovie()

    }
    
    @IBAction func clearCacheMenuItemDidSelect(sender: AnyObject) {

        let paths = [
            "\(kAppHomePath)/images",
            "\(kAppHomePath)/videos"
        ]
        
        let fileManager = NSFileManager.defaultManager()

        paths.enumerate().forEach { (index: Int, element: String) in

            let contents = try! fileManager.contentsOfDirectoryAtPath(element)
            for content in contents {
                do {
                    try fileManager.removeItemAtPath("\(element)/\(content)")
                } catch let error as NSError {
                    print("failed to remove file: \(error.description)");
                }
            }
        }
        
        // Alert
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.messageText = "Complete!!"
        alert.informativeText = "finished clearing cache"
        alert.runModal()
        
    }
    
}
