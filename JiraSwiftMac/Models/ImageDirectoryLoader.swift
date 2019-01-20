/*
 * ImageDirectoryLoader.swift
 * SlidesMagic
 *
 * Created by Gabriel Miro on Oct 2016.
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa

class ImageDirectoryLoader: NSObject {
    
    fileprivate var imageFiles = [ImageFile]()
    fileprivate class SectionAttributes {
        var images: [ImageFile] = [ImageFile]()
        var name: String = ""
    }
    
    fileprivate var sectionsAttributesArray = [SectionAttributes]()
    
    func setupDataForUrls(_ urls: [URL]?) {
        
        if let urls = urls {                    // When new folder
            createImageFilesForUrls(urls)
        }
        
        if sectionsAttributesArray.count > 0 {  // If not first time, clean old sectionsAttributesArray
            sectionsAttributesArray.removeAll()
        }
        
        
        setupDataForMultiSectionMode()
        
    }
    
    fileprivate func setupDataForMultiSectionMode() {
        
        var sectionsByFolder = [String: SectionAttributes]()
        var sections = [SectionAttributes]()
        
        for file in imageFiles {
            let stringPath = file.url.path as NSString
            let pathWithoutFile = stringPath.deletingLastPathComponent
            
            var section = sectionsByFolder[pathWithoutFile]
            
            if section == nil {
                section = SectionAttributes()
                section?.name = (pathWithoutFile as NSString).lastPathComponent
                sections.append(section!)
                sectionsByFolder[pathWithoutFile] = section
            }
            
            var imageArray = section!.images
            imageArray.append(file)
            section?.images = imageArray
        }
        
        sections = sections.sorted(by: { (attr1, attr2) -> Bool in
            return attr1.name < attr2.name
        })
        
        self.sectionsAttributesArray = sections
    }
    
    fileprivate func createImageFilesForUrls(_ urls: [URL]) {
        if imageFiles.count > 0 {   // When not initial folder
            imageFiles.removeAll()
        }
        for url in urls {
            if let imageFile = ImageFile(url: url) {
                imageFiles.append(imageFile)
            }
        }
    }
    
    fileprivate func getFilesURLFromFolder(_ folderURL: URL) -> [URL]? {
        
        let options: FileManager.DirectoryEnumerationOptions =
            [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
        let fileManager = FileManager.default
        let resourceValueKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey]
        
        guard let directoryEnumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: resourceValueKeys,
                                                               options: options, errorHandler: { url, error in
                                                                print("`directoryEnumerator` error: \(error).")
                                                                return true
        }) else { return nil }
        
        var urls: [URL] = []
        for case let url as URL in directoryEnumerator {
            do {
                let resourceValues = try (url as NSURL).resourceValues(forKeys: resourceValueKeys)
                guard let isRegularFileResourceValue = resourceValues[URLResourceKey.isRegularFileKey] as? NSNumber else { continue }
                guard isRegularFileResourceValue.boolValue else { continue }
                guard let fileType = resourceValues[URLResourceKey.typeIdentifierKey] as? String else { continue }
                guard UTTypeConformsTo(fileType as CFString, "public.image" as CFString) else { continue }
                urls.append(url)
            }
            catch {
                print("Unexpected error occured: \(error).")
            }
        }
        return urls
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        return sectionsAttributesArray[section].images.count
    }
    
    func numberOfSections() -> Int {
        return self.sectionsAttributesArray.count
    }
    
    func sectionNameForSectionIndex(index: Int) -> String {
        return self.sectionsAttributesArray[index].name
    }
    
    func imageFileForIndexPath(indexPath: IndexPath) -> ImageFile {
        let row = indexPath.item
        let imageFiles = sectionsAttributesArray[indexPath.section].images
        let imageFile = imageFiles[row ]
        return imageFile
    }
    
    func loadDataForFolderWithUrls(_ folderURLs: [URL]) {
        var urls = [URL]()
        for folderURL in folderURLs {
            let thisFolderUrls = getFilesURLFromFolder(folderURL) ?? [URL]()
            urls = urls + thisFolderUrls
            
        }
        
        urls.sort { (url1, url2) -> Bool in
            guard let attributes1 = try? FileManager.default.attributesOfItem(atPath: url1.path) else {
                return true
            }
            
            guard let attributes2 = try? FileManager.default.attributesOfItem(atPath: url2.path) else {
                return true
            }
            
            guard let modifiedDate1 = attributes1[FileAttributeKey.modificationDate] as? Date else {
                return true
            }
            
            guard let modifiedDate2 = attributes2[FileAttributeKey.modificationDate] as? Date else {
                return true
            }
            
            return modifiedDate1.compare(modifiedDate2) == ComparisonResult.orderedDescending
            
        }
        
        setupDataForUrls(urls)
    }
    
}
