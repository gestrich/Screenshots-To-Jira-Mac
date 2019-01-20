//
//  Utilities.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/27/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Cocoa

class Utilities: NSObject {
    
    func getString(title: String, question: String, defaultValue: String) -> String {
        let msg = NSAlert()
        msg.addButton(withTitle: "OK")      // 1st button
        msg.addButton(withTitle: "Cancel")  // 2nd button
        msg.messageText = title
        msg.informativeText = question
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        textField.stringValue = defaultValue
        let textWithoutExtension = (defaultValue as NSString).deletingPathExtension
        
        msg.accessoryView = textField
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textField.becomeFirstResponder()
            if let editor = textField.currentEditor() {
                editor.selectedRange = NSRange(location: 0, length: textWithoutExtension.count)
            }
        }
        let response: NSApplication.ModalResponse = msg.runModal()
        
        if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
            return textField.stringValue
        } else {
            return ""
        }
    }


}
