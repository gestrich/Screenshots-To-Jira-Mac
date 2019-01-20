//
//  WindowController.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/20/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

//From https://www.raywenderlich.com/783-nscollectionview-tutorial

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        if let window = window, let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            window.setFrame(NSRect(x: screenRect.origin.x, y: screenRect.origin.y, width: screenRect.width/2.0, height: screenRect.height / 2.0), display: true)
            
        }
        


    }
    
    @IBAction func openAnotherFolder(_ sender: AnyObject) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories  = true
        openPanel.canChooseFiles        = false
        openPanel.showsHiddenFiles      = false
        
        openPanel.beginSheetModal(for: self.window!) { (response) -> Void in
            guard response == NSApplication.ModalResponse.OK else {return}
            let viewController = self.contentViewController as? ImageCollectionViewController
            if let viewController = viewController, let URL = openPanel.url {
                viewController.loadDataForNewFolderWithUrl(URL)
            }
        }
    }
    
        @IBAction func quit(_ sender: AnyObject) {
            NSApplication.shared.terminate(self)
    }

}
