//
//  ImageCollectionViewController.swift
//  JiraSwiftMac
//
//  Created by Bill Gestrich on 1/20/19.
//  Copyright © 2019 Bill Gestrich. All rights reserved.
//

import Cocoa

class ImageCollectionViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var imageTitle: ClickableTextField!
    let imageDirectoryLoader = ImageDirectoryLoader()
    var directoryMonitors: [DirectoryMonitor] = [DirectoryMonitor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadImageLoader()
        
        // Do view setup here.
        configureCollectionView()
        
        self.imageTitle.clickBlock = {
            let selectedFile = self.getSelectedFile()
            if let selectedFile = selectedFile {
                self.promptToRename(file: selectedFile)
            }

        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ImageCollectionViewController.foregroundNotification), name: NSApplication.didBecomeActiveNotification, object: nil)

    }
    
    func reloadImageLoader(){
        
        let downloadsFolder = URL(fileURLWithPath: "/Users/bill/Downloads", isDirectory: true)
        let desktopFolder = URL(fileURLWithPath: "/Users/bill/Desktop", isDirectory: true)
        let dropboxFolder = URL(fileURLWithPath: "/Users/bill/Dropbox/screenshots", isDirectory: true)
        
        let urls = [downloadsFolder, desktopFolder, dropboxFolder]
        
        imageDirectoryLoader.loadDataForFolderWithUrls(urls)
        

        var monitors = [DirectoryMonitor]()
        for url in urls {
            let monitor = DirectoryMonitor(URL: url)
            monitor.startMonitoring()
            monitor.delegate = self
            monitors.append(monitor)
        }
        
        for monitor in self.directoryMonitors {
            monitor.stopMonitoring()
        }
        
        for monitor in monitors {
            monitor.startMonitoring()
        }
        
        self.directoryMonitors = monitors

    }
    
    func loadDataForNewFolderWithUrl(_ folderURL: URL) {
        imageDirectoryLoader.loadDataForFolderWithUrls([folderURL])
        self.collectionView.reloadData()
    }
    
    fileprivate func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        
        flowLayout.sectionInset = NSEdgeInsets(top: 30.0, left: 20.0, bottom: 30.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        
        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.backgroundColors = [NSColor.black]
        
        //TODO: Tutorial says this more performant but doesn't work.
        //        collectionView.layer?.backgroundColor = NSColor.green.cgColor
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func rightMouseDown(with event: NSEvent) {
        if let item = itemFromClickEvent(event: event) {
            let indexPath = self.collectionView.indexPath(for: item)!
            let set = Set([indexPath])

            self.collectionView.deselectItems(at: self.collectionView.selectionIndexPaths)
            self.collectionView.selectItems(at: set , scrollPosition: NSCollectionView.ScrollPosition.nearestHorizontalEdge)
            if let imageFile = item.imageFile{
                self.setSelectedFile(file: imageFile)
            }

            self.showRightClickMenu(item: item, event: event)
        }
    }
    
    func itemFromClickEvent(event: NSEvent) -> CollectionViewItem? {
        guard let contentView = NSApplication.shared.mainWindow?.contentView else {
            return nil
        }
        
        let locationInWindow = event.locationInWindow
        
        //Convert as locationInWindow y coord start from bottom.
        //locationInWindow = CGPoint(x: locationInWindow.x, y: contentView.frame.height - locationInWindow.y)
        
        let locationInView = contentView.convert(locationInWindow, to: self.collectionView)
        
        if let doubleClickedIndexPath = collectionView.indexPathForItem(at: locationInView) {
            
            if let item = collectionView.item(at: doubleClickedIndexPath)  as? CollectionViewItem {
                return item
            }
        }
        
        return nil
    }
    
    
    func showRightClickMenu(item: CollectionViewItem, event: NSEvent){
        let theMenu = NSMenu(title: "Contextual menu")
        
        let deleteMenuItem = NSMenuItem(title: "Delete", action: #selector(ImageCollectionViewController.delete), keyEquivalent: "")
        deleteMenuItem.representedObject = item
        theMenu.addItem(deleteMenuItem)
        
        let jiraMenuItem = NSMenuItem(title: "Jira", action: #selector(ImageCollectionViewController.sendToJira), keyEquivalent: "")
        jiraMenuItem.representedObject = item
        theMenu.addItem(jiraMenuItem)
        
        let renameMenuItem = NSMenuItem(title: "Rename", action: #selector(ImageCollectionViewController.rename), keyEquivalent: "")
        renameMenuItem.representedObject = item
        theMenu.addItem(renameMenuItem)
        
        let openFileMenuItem = NSMenuItem(title: "Preview", action: #selector(ImageCollectionViewController.openSelectedFile), keyEquivalent: "")
        openFileMenuItem.representedObject = item
        theMenu.addItem(openFileMenuItem)
        
        for item: AnyObject in theMenu.items {
            if let menuItem = item as? NSMenuItem {
                menuItem.target = self
            }
        }
        
        NSMenu.popUpContextMenu(theMenu, with:event, for:self.view)
    }
    
    @objc func delete(menuItem:NSMenuItem){
        if let item = menuItem.representedObject as? CollectionViewItem {
            if let imageFile = item.imageFile {
                do {
                    try FileManager.default.removeItem(at: imageFile.url)
                    self.reloadImageLoader()
                    self.imageView.image = nil
                    self.collectionView.reloadData()
                } catch {
                    print("Error deleting file \(error)")
                }
            }
        }
    }
    
    @objc func rename(menuItem:NSMenuItem){
        if let item = menuItem.representedObject as? CollectionViewItem {
            if let imageFile = item.imageFile {
                self.promptToRename(file: imageFile)
            }
        }
    }
    
    func promptToRename(file: ImageFile){
        do {
            let sourceUrl = file.url
            let sourceFileName = sourceUrl.lastPathComponent
            
            if let urlWithoutFileName = (file.url as NSURL).deletingLastPathComponent {
                
                let newName = Utilities().getString(title: "New File Name", question: "Enter the new file name", defaultValue: sourceFileName)
                let newUrl = urlWithoutFileName.appendingPathComponent(newName)
                try FileManager.default.moveItem(at: sourceUrl, to: newUrl)
                self.reloadImageLoader()
                self.collectionView.reloadData()
            }
            
        } catch {
            print("Error deleting file \(error)")
        }
    }
    
    @objc func sendToJira(menuItem:NSMenuItem){
        if let item = menuItem.representedObject as? CollectionViewItem {
            if let imageFile = item.imageFile {
                self.performSegue(withIdentifier: "JiraShow", sender: self)
            }
        }
    }
    
    @objc func openSelectedFile(menuItem:NSMenuItem){
        if let item = menuItem.representedObject as? CollectionViewItem {
            if let imageFile = item.imageFile {
                NSWorkspace.shared.openFile(imageFile.url.path)
            }
        }
    }
    
    @objc func foregroundNotification(){
        //        self.reloadImageLoader()
        //        self.collectionView.reloadData()
    }
    
    func setSelectedFile(file: ImageFile){
        self.imageView.image = NSImage(contentsOfFile: file.url.path)
        self.imageTitle.stringValue = file.fileName
    }
    
    func getSelectedFile() -> ImageFile? {
        let selectedIndices = self.collectionView.selectionIndexPaths
        if let firstIndex = selectedIndices.first {
            if let item = collectionView.item(at: firstIndex)  as? CollectionViewItem {
                return item.imageFile
            }
        }
        
        return nil
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "JiraShow" {
            let vc = segue.destinationController as! JiraViewController
            if let selectedFile = self.getSelectedFile(){
                vc.selectedFilePath = selectedFile.url.path
            }
        }
    }
}
extension ImageCollectionViewController : NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let firstIndexPath = indexPaths.first!
        let item = self.imageDirectoryLoader.imageFileForIndexPath(indexPath: firstIndexPath)
        self.setSelectedFile(file: item)
    }
}

extension ImageCollectionViewController : NSCollectionViewDataSource {
    
    // 1
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return imageDirectoryLoader.numberOfSections()
    }
    
    // 2
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageDirectoryLoader.numberOfItemsInSection(section)
    }
    
    // 3
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        // 4
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem else {return item}
        
        // 5
        let imageFile = imageDirectoryLoader.imageFileForIndexPath(indexPath: indexPath)
        collectionViewItem.imageFile = imageFile
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderView"), for: indexPath) as! HeaderView
        view.sectionTitle.stringValue = imageDirectoryLoader.sectionNameForSectionIndex(index: indexPath.section)
        let numberOfItemsInSection = imageDirectoryLoader.numberOfItemsInSection(indexPath.section)
        view.imageCount.stringValue = "\(numberOfItemsInSection) image files"
        return view
        
    }
    
}

extension ImageCollectionViewController : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: 1000, height: 40)
    }
}

extension ImageCollectionViewController : DirectoryMonitorDelegate {

    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor){
        DispatchQueue.main.async {
            self.reloadImageLoader()
            self.collectionView.reloadData()
        }
    }
}
