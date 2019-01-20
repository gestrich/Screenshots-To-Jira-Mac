//
//  ClickableTextField.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/27/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Cocoa

class ClickableTextField: NSTextField {
    
    var clickBlock : (() -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func mouseDown(with event: NSEvent) {
        print("mouseDown")
        if let clickBlock = clickBlock {
            clickBlock()
        }
    }
    
}
