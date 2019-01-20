//
//  JiraViewController.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/19/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Cocoa
import JiraSwift

class JiraViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    var recentIssues: [Issue]?
    var urlBase: String!
    var jiraClient: JiraRestClient!
    var selectedFilePath: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Insert code here to customize the view
        if let item = self.extensionContext?.inputItems[0] as? NSExtensionItem {
            if let attachments = item.attachments {
                NSLog("Attachments = %@", attachments as NSArray)
            } else {
                NSLog("No Attachments")
            }
        }

        //Set your own credentials here
        let auth = BasicAuth(username: "", password: "")
        self.urlBase = ""
        
        let baseUrl = (self.urlBase as NSString).appending("/rest/")
        self.jiraClient = JiraRestClient(baseURL: baseUrl, auth: auth)
        let filter = JQLFilter(jql: "issue in issueHistory() ORDER BY lastViewed DESC")
        self.jiraClient.issues(for: filter, completionBlock: { (issues) in
            DispatchQueue.main.async { 
                self.recentIssues = issues
                self.tableView?.reloadData()
            }
            
        }) { (error) in
            print("Error")
        }
        // Do any additional setup after loading the view.
    }
    
    //Mark NSTableViewDataSource
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            // Get a new ViewCell 
        let cellView: NSTableCellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
            
            // Since this is a single-column table view, this would not be necessary.
            // But it's a good practice to do it in order by remember it when a table is multicolumn.

        if row == 0 {
            //Enter case row
            cellView.textField?.stringValue = "*Enter Case*"
        } else {
            let jiraCase = self.jiraIssueForRow(row: row)!
            if tableColumn!.identifier.rawValue == "Case Key" {
                cellView.textField!.stringValue = jiraCase.key
            } else if tableColumn!.identifier.rawValue == "Case Summary" {
                cellView.textField!.stringValue = jiraCase.fields.summary
            }
        }

        return cellView
    }
    

    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 1 + (self.recentIssues?.count ?? 0)
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        print("did click column \(tableColumn)")
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow
        self.tableView.deselectRow(selectedRow)
        let jiraCase = self.jiraIssueForRow(row: selectedRow)
        if selectedRow == 0 {
            //Prompt for input
            let caseKey = Utilities().getString(title: "Case", question: "Enter Case Key", defaultValue: "")
            self.uploadCase(caseKey: caseKey)
            
        } else if let jiraCase = jiraCase {
            self.uploadCase(caseKey: jiraCase.key)

        }
    }
    
    func uploadCase(caseKey: String){
        let urlString = (self.urlBase as NSString).appending("/browse/") + caseKey
        
        let escapedFilePath = self.selectedFilePath.replacingOccurrences(of: " ", with: "%20")
        self.jiraClient.uploadFile(filePath: escapedFilePath, issueIdentifier: caseKey, completionBlock: {
            
//            let _ = try? FileManager.default.removeItem(atPath: self.selectedFilePath)
            
            DispatchQueue.main.async {
                if let url = URL(string: urlString),
                    NSWorkspace.shared.open(url) {
                    print("default browser was successfully opened")
                }
                self.dismiss(self)
            }
            
        }) { (error) in
            print("error uploading file \(error)")
            self.dismissAsync()
        }
    }
    
    func dismissAsync(){
        DispatchQueue.main.async {
            self.dismiss(self)
        }
    }
    
    func jiraIssueForRow(row: Int) -> Issue? {
        if row < 1 {
            return nil
        } else {
            return self.recentIssues![row - 1]
        }
    }


    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

