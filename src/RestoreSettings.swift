//
//  RestoreSettings.swift
//  RDM-2
//
//  Created by JNR on 31/08/2020.
//  Copyright © 2020 гык-sse2. All rights reserved.
//

import Cocoa

@objc class RestoreSettingsItem : NSMenuItem {
	@objc var vendorID	  : UInt32
	@objc var productID	  : UInt32
	@objc var displayName : String
		  var filePath	  : String

	private static let backupDir =
		URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(
			"Library/Application Support/\(Bundle.main.bundleIdentifier!)/Backups").path

	@objc init(title : String, action : Selector, vendorID : UInt32, productID : UInt32, displayName : String) {
		self.vendorID	 = vendorID // 1552
		self.productID	 = productID // 0x9c2c
		self.displayName = displayName // "DEBUG"
		self.filePath	 = String(format: "\(ViewController.dirformat)/\(ViewController.fileformat)", self.vendorID, self.productID)

		super.init(title: title, action: action, keyEquivalent: "")
	}

	required init(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	static func backupSettings(originalPlistPath : String) -> NSDictionary? {
		let plistSpecificPath = URL(fileURLWithPath: originalPlistPath).pathComponents.suffix(2)

		var backupScripts 	  = [String]()
		let backupDir		  = "\(RestoreSettingsItem.backupDir)/\(plistSpecificPath.first!)"

		if FileManager.default.fileExists(atPath: backupDir) {
			return nil
		}

		backupScripts.append("mkdir -p '\(backupDir)'")
		backupScripts.append("cp '\(originalPlistPath)' '\(backupDir)/\(plistSpecificPath.last!)'")

		return execShellScript(backupScripts.joined(separator: " && "))
	}

//	@objc static func restoreAllSettings() {
//		var restoreScripts = [String]()
//		let originalDir	   = ViewController.rootdir.hasPrefix("/System") ? ViewController.rootdir : "/System" + ViewController.rootdir
//
//		for dir in (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: backupDir), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] {
//			for file in (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [] {
//				let specificPaths = file.pathComponents.suffix(2)
//				restoreScripts.append("mkdir -p '\(originalDir)/\(specificPaths.first!)'")
//				restoreScripts.append("mv -f '\(file.path)' '\(originalDir)/\(specificPaths.joined(separator: "/"))'")
//			}
//		}
//
//		if !restoreScripts.isEmpty {
//			if let errDict = execShellScript(restoreScripts.joined(separator: " && "), withAdminPriv: true) {
//				fatalError("Cannot restore original settings\n\(errDict.object(forKey: "NSAppleScriptErrorBriefMessage") as! String)")
//			}
//		}
//	}

	@objc func restoreSettings() -> Bool {
		var restoreScripts = [String]()
		var rootdirs	   = [ViewController.rootdir]

		if ViewController.afterCatalina
			&& ViewController.rootWriteable {
			rootdirs.append("/System" + rootdirs[0])
		}

		for dir in rootdirs {
			if dir.hasPrefix("/System") {
				restoreScripts.append("mv -f '\(RestoreSettingsItem.backupDir)/\(filePath)' '\(dir)/\(filePath)'")
			} else if FileManager.default.fileExists(atPath: "\(dir)/\(filePath)") {
					restoreScripts.append("rm -f '\(dir)/\(filePath)'")
			}
		}

		if restoreScripts.count > 0 {
			if let errDict = execShellScript(restoreScripts.joined(separator: " && "),
											 withAdminPriv: true) {
				constructAlert(errDict).runModal()
				return false
			}
		}

		return true
	}
}
