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
			  var plist	   = NSMutableDictionary()
			  var sysplist = NSMutableDictionary()

	@IBOutlet weak var displayName : NSTextField!
	@objc 		   var vendorID    : UInt32		  = 0
	@objc 		   var productID   : UInt32		  = 0
				   var resolutions : [Resolution] = []
				   var sysResols   : [Resolution] = []
	
	@objc var displayProductName : String {
		get {
			return displayName.stringValue
		}
		set(value) {
			displayName.stringValue = value
		}
	}

	var dir : String {
		get {
//			return String(format:ViewController.dirformat, 40557) // DEBUG
			return String(format:ViewController.dirformat, vendorID)
		}
	}
	
	var fileName : String {
		get {
//			return String(format: "\(dir)/DisplayProductID-%x", 23313) // DEBUG
			return String(format:"\(dir)/DisplayProductID-%x", productID)
		}
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()

		plist = NSMutableDictionary.init(contentsOf: URL.init(fileURLWithPath: fileName)) ?? NSMutableDictionary()

		if let a = plist[kDisplayProductName] as? String {
			displayProductName = a
		}
		
		resolutions = [Resolution]()
		if let a = plist["scale-resolutions"] {
			if let b = a as? NSArray {
				resolutions = (b as Array).map { Resolution.parse(nsdata: $0 as? NSData) }
			}
		}

//		For backward-compatibility
		if FileManager.default.fileExists(atPath: "/System" + fileName) {
			if ViewController.rootWriteable && ViewController.afterCatalina {
				sysplist = NSMutableDictionary.init(contentsOf: URL.init(fileURLWithPath: "/System" + fileName)) ?? NSMutableDictionary()
				if let a = sysplist["scale-resolutions"] {
					if let b = a as? NSArray {
						sysResols = (b as Array).map { Resolution.parse(nsdata: $0 as? NSData) }
						for res in sysResols {
							if !(resolutions.contains { $0 == res }) {
								resolutions.append(res)
							}
						}
					}
				}
			}
		}
		
		DispatchQueue.main.async {
			self.arrayController.content = self.resolutions
		}
	}
	
	@IBAction func add(_ sender: Any) {
		resolutions.append(Resolution())
		arrayController.content = resolutions
		arrayController.rearrangeObjects()
	}
	
	@IBOutlet weak var removeButton: NSButton!
	
	@IBAction func remove(_ sender: Any) {
		if arrayController.selectionIndex >= 0 {
			let removed = resolutions.remove(at: arrayController.selectionIndex)
			if let idx = sysResols.firstIndex(where: { $0 == removed }) {
				sysResols.remove(at: idx) // For backward compatibility
			}
			arrayController.content = resolutions
			arrayController.rearrangeObjects()
		}
	}

	@IBAction func save(_ sender: Any) {
		let tmpFile	   = NSTemporaryDirectory() + "tmp",
			tmpFileSys = NSTemporaryDirectory() + "tmp_sys"

		plist.setValue(displayProductName as NSString, forKey: kDisplayProductName)
		plist.setValue(resolutions.map { $0.toData() } as NSArray, forKey: "scale-resolutions")

		plist.write(toFile: tmpFile, atomically: false)
		var saveScript = "mkdir -p '\(dir)' && cp '\(tmpFile)' '\(fileName)'"

//		For backward compatibility
		if ViewController.rootWriteable && ViewController.afterCatalina {
			sysplist.setValue(displayProductName as NSString, forKey: kDisplayProductName)
			sysplist.setValue(sysResols.map { $0.toData() } as NSArray, forKey: "scale-resolutions")

			sysplist.write(toFile: tmpFileSys, atomically: false)
			saveScript += " && mkdir -p '\("/System" + dir)' && cp '\(tmpFileSys)' '\("/System" + fileName)'"
		}

		execAppleScript("do shell script \"" + saveScript + "\"", withAdminPriv: true)

		try? FileManager.default.removeItem(atPath: tmpFile)
		try? FileManager.default.removeItem(atPath: tmpFileSys)
		view.window!.close()
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
}
