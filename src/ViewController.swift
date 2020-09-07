//
//  ViewController.swift
//  RDM-2
//
//  Created by гык-sse2 on 21/08/2018.
//  Copyright © 2018 гык-sse2. All rights reserved.
//

import Cocoa

@objc class ViewController: NSViewController {

    // Assume SIP status and OS version are constants
    static let rootWriteable = !isSIPActive()
    static let afterCatalina = ProcessInfo().isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0))
    static let rootdir       = ( ViewController.afterCatalina
        ?  "" : "/System" ) + "/Library/Displays/Contents/Resources/Overrides"
    static let dirformat     = "DisplayVendorID-%x"
    static let fileformat    = "DisplayProductID-%x"

    @IBOutlet var arrayController : NSArrayController!
              var calcController  : SheetViewController!
              var plists          : [NSMutableDictionary] = []

    @IBOutlet weak var displayName : NSTextField!
    @objc          var vendorID    : UInt32         = 0
    @objc          var productID   : UInt32         = 0
                   var resolutions : [[Resolution]] = []

    // For help
    var helpPopover     : NSPopover!

    @objc var displayProductName : String {
        get {
            return displayName.stringValue
        }
        set(value) {
            displayName.stringValue = value
        }
    }

    var dirs : [String] {
        get {
            let destdir = String(format: "\(ViewController.rootdir)/\(ViewController.dirformat)", vendorID)

            return ViewController.rootWriteable && ViewController.afterCatalina
                ? [destdir, "/System" + destdir] : [destdir]
        }
    }

    var fileNames : [String] {
        get {
            return dirs.map { String(format:"\($0)/\(ViewController.fileformat)", productID) }
        }
    }

    // For closing when esc key is pressed
    override func cancelOperation(_ sender: Any?) {
        self.view.window!.close()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        plists = fileNames.map { NSMutableDictionary(contentsOf: URL(fileURLWithPath: $0)) ?? NSMutableDictionary() }

        if let a = plists[0][kDisplayProductName] as? String {
            displayProductName = a
        }

        resolutions = [[Resolution]](repeating: [Resolution](), count: plists.count)
        for (idx, plist) in plists.enumerated() {
            if let a = plist["scale-resolutions"] {
                if let b = a as? NSArray {
                    resolutions[idx] = (b as Array).map { Resolution(nsdata: $0 as? NSData) }

                    if idx != 0 && resolutions.count > 1 {
                        for res in resolutions[idx] {
                            if !(resolutions[0].contains { $0 == res }) {
                                resolutions[0].append(res)
                            }
                        }
                    }
                }
            }
        }

        // Initialize subviews
        calcController = (storyboard!.instantiateController(withIdentifier: "calculator") as! SheetViewController)

        helpPopover = NSPopover()
        helpPopover.contentViewController = (storyboard!.instantiateController(withIdentifier: "helpMessage") as! NSViewController)
        helpPopover.behavior = .semitransient

        // For better UI
        view.window!.standardWindowButton(.miniaturizeButton)!.isHidden = true
        view.window!.standardWindowButton(.zoomButton)!.isHidden = true
        view.window!.styleMask.insert(.resizable)

        DispatchQueue.main.async {
            self.arrayController.content = self.resolutions[0]
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.level = .floating // Always on top
    }

    @IBAction
    func add(_ sender: Any) {
        resolutions[0].append(Resolution())
        arrayController.content = resolutions[0]
        arrayController.rearrangeObjects()
    }

//    @IBOutlet weak var removeButton: NSButton!

    @IBAction func remove(_ sender: Any) {
        if arrayController.selectionIndexes.count > 0 {
            let removed = arrayController.selectionIndexes.map { resolutions[0][$0] }

            // For backward compatibility
            if resolutions.count > 1 {
                for rem in removed {
                    if let j = resolutions[1].firstIndex(where: { $0 == rem }) {
                        resolutions[1].remove(at: j)
                    }
                }
            }

            resolutions[0].remove(at: arrayController.selectionIndexes)
            arrayController.content = resolutions[0]
            arrayController.rearrangeObjects()
        }
    }

    @IBAction func save(_ sender: Any) {
        var saveScripts = [String]()

        if ViewController.rootWriteable {
            if let error = RestoreSettingsItem.backupSettings(originalPlistPath: fileNames.last!) {
                NSAlert(fromDict: error).beginSheetModal(for: view.window!)
                return
            }
        }

        for ((plist, resol), (dir, fileName)) in zip(zip(plists, resolutions), zip(dirs, fileNames)) {
            let tmpFile = NSTemporaryDirectory() + UUID().uuidString

            plist.setValue(displayProductName as NSString, forKey: kDisplayProductName)
            plist.setValue(resol.map { $0.toData() } as NSArray, forKey: "scale-resolutions")
            plist.write(toFile: tmpFile, atomically: false)

            saveScripts.append("mkdir -p '\(dir)'")
            saveScripts.append("cp '\(tmpFile)' '\(fileName)'")
            saveScripts.append("rm '\(tmpFile)'")
        }

        if let error = NSAppleScript.executeAndReturnError(source: saveScripts.joined(separator: " && "),
                                                           asType: .shell,
                                                           withAdminPriv: true) {
            NSAlert(fromDict: error).beginSheetModal(for: view.window!)
        } else {
            view.window!.close()
        }
    }

    @IBAction func calcAspectRatio(_ sender: Any) {
        presentAsSheet(calcController)
    }

    @IBAction func displayHelpmessage(_ sender: Any) {
        guard let sender = sender as? NSButton else { return }

        if helpPopover.isShown {
            helpPopover.close()
        } else {
            helpPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
