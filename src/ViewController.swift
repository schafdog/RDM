//
//  ViewController.swift
//  RDM-2
//
//  Created by гык-sse2 on 21/08/2018.
//  Copyright © 2018 гык-sse2. All rights reserved.
//

import Cocoa

@objc class ViewController: NSViewController {

//	 Assume SIP status and OS version are constants
	static let rootWriteable = !isSIPActive()
	static let afterCatalina = ProcessInfo().isOperatingSystemAtLeast(
		OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0))
	static let dirformat	 = ( ViewController.afterCatalina
		?  "" : "/System" ) + "/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-%x"

	@IBOutlet var arrayController : NSArrayController!
			  var plists		  : [NSMutableDictionary] = []

	@IBOutlet weak var displayName : NSTextField!
	@objc 		   var vendorID    : UInt32		  = 0
	@objc 		   var productID   : UInt32		  = 0
				   var resolutions : [[Resolution]] = []
	
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
			let destdir = String(format:ViewController.dirformat, vendorID)

			return ViewController.rootWriteable && ViewController.afterCatalina
				? [destdir, "/System" + destdir] : [destdir]
		}
	}
	
	var fileNames : [String] {
		get {
			return dirs.map { String(format:"\($0)/DisplayProductID-%x", productID) }
		}
	}

	// For closing when esc key is pressed
	override func cancelOperation(_ sender: Any?) {
		self.view.window!.close()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()

		plists = fileNames.map { NSMutableDictionary.init(contentsOf: URL.init(fileURLWithPath: $0)) ?? NSMutableDictionary() }

		if let a = plists[0][kDisplayProductName] as? String {
			displayProductName = a
		}
		
		resolutions = []
		for (idx, plist) in plists.enumerated() {
			if let a = plist["scale-resolutions"] {
				if let b = a as? NSArray {
					resolutions.append(
						(b as Array).map { Resolution(nsdata: $0 as? NSData) }
					)

					if idx != 0 && resolutions.count > 1 {
						for res in resolutions.last! {
							if !(resolutions[0].contains { $0 == res }) {
								resolutions[0].append(res)
							}
						}
					}
				}
			}
		}
		
		DispatchQueue.main.async {
			self.arrayController.content = self.resolutions[0]
		}
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		view.window?.level = .floating // Always on top
	}
	
	@IBAction func add(_ sender: Any) {
		resolutions[0].append(Resolution())
		arrayController.content = resolutions[0]
		arrayController.rearrangeObjects()
	}
	
	@IBOutlet weak var removeButton: NSButton!
	
	@IBAction func remove(_ sender: Any) {
		if arrayController.selectionIndex >= 0 {
			let removed = resolutions[0].remove(at: arrayController.selectionIndex)
			arrayController.content = resolutions[0]
			arrayController.rearrangeObjects()

			// For backward compatibility
			if resolutions.count > 1 {
				if let idx = resolutions[1].firstIndex(where: { $0 == removed }) {
					resolutions[1].remove(at: idx)
				}
			}
		}
	}

	@IBAction func save(_ sender: Any) {
		var saveScripts: [String] = []

		for ((plist, resol), (dir, fileName)) in zip(zip(plists, resolutions), zip(dirs, fileNames)) {
			let tmpFile = NSTemporaryDirectory() + UUID().uuidString

			plist.setValue(displayProductName as NSString, forKey: kDisplayProductName)
			plist.setValue(resol.map { $0.toData() } as NSArray, forKey: "scale-resolutions")
			plist.write(toFile: tmpFile, atomically: false)

			saveScripts.append("mkdir -p '\(dir)' && cp '\(tmpFile)' '\(fileName)' && rm '\(tmpFile)'")
		}

		if let errDict = execAppleScript("do shell script \"" + saveScripts.joined(separator: " && ") + "\"",
									 withAdminPriv: true) {
			let alert = NSAlert()
			if let reason = errDict.object(forKey: "NSAppleScriptErrorBriefMessage") {
				alert.messageText = (reason as! NSString) as String
			} else {
				alert.messageText = "Unknown error, please try again."
				print(errDict)
			}
			alert.alertStyle = .critical
			alert.beginSheetModal(for: view.window!)
		} else {
			view.window!.close()
		}
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
}
