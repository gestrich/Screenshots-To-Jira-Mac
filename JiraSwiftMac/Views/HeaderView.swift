//
//  HeaderView.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/26/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Cocoa

class HeaderView: NSView {
    
    @IBOutlet weak var sectionTitle: NSTextField!
        @IBOutlet weak var imageCount: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(calibratedWhite: 0.8, alpha: 1.0).set()
        __NSRectFillUsingOperation(dirtyRect, NSCompositingOperation.sourceOver)
    }
    
}
